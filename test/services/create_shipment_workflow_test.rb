require "test_helper"
require "securerandom"

class CreateShipmentWorkflowTest < ActiveSupport::TestCase
  test "shipment creation generates expected non-child documents and dependencies" do
    shipment = create(:shipment)

    assert shipment.shipment_documents.exists?(document_template: shipment.organization.document_templates.find_by!(code: "master_agreement"))
    assert shipment.shipment_documents.exists?(document_template: shipment.organization.document_templates.find_by!(code: "purchase_order"))
    assert shipment.shipment_documents.exists?(document_template: shipment.organization.document_templates.find_by!(code: "shipping_instruction"))
    assert shipment.shipment_document_dependencies.exists?
  end

  test "generation is idempotent" do
    shipment = create(:shipment)
    counts = [ shipment.shipment_documents.count, shipment.shipment_document_dependencies.count ]

    assert_no_changes -> { [ shipment.shipment_documents.count, shipment.shipment_document_dependencies.count ] } do
      CreateShipmentWorkflow.call(shipment)
    end

    assert_equal counts, [ shipment.shipment_documents.count, shipment.shipment_document_dependencies.count ]
  end

  test "rolls back generated records when dependency building fails" do
    shipment = create(:shipment)
    runtime_dependencies_for(shipment).destroy_all
    shipment.shipment_documents.find_each { |document| document.shipment_document_field_values.destroy_all }
    shipment.shipment_documents.destroy_all

    with_failing_dependency_builder do
      assert_raises(ActiveRecord::RecordInvalid) { CreateShipmentWorkflow.call(shipment) }
    end

    assert_equal 0, shipment.shipment_documents.count
    assert_equal 0, shipment.shipment_document_dependencies.count
    assert_equal 0, shipment.organization.shipment_document_field_values.joins(:shipment_document).where(shipment_documents: { shipment_id: shipment.id }).count
  end

  test "adding lots and containers generates child-grain documents" do
    shipment = create(:shipment)

    create(:shipment_lot, shipment: shipment)
    create(:shipment_container, shipment: shipment)
    shipment.reload

    assert shipment.shipment_documents.joins(:document_template).exists?(document_templates: { grain: "lote" })
    assert shipment.shipment_documents.joins(:document_template).exists?(document_templates: { grain: "contenedor" })
  end

  test "destination and incoterm filters control conditional documents" do
    fob_shipment = create(:shipment, destination_country: "China", incoterm: "FOB")
    cif_shipment = create(:shipment, destination_country: "China", incoterm: "CIF")

    assert fob_shipment.shipment_documents.joins(:document_template).exists?(document_templates: { code: "certificate_of_origin" })
    assert_not fob_shipment.shipment_documents.joins(:document_template).exists?(document_templates: { code: "marine_insurance" })
    assert cif_shipment.shipment_documents.joins(:document_template).exists?(document_templates: { code: "marine_insurance" })
  end

  private

    def runtime_dependencies_for(shipment)
      ShipmentDocumentDependency.where(shipment_document_id: shipment.shipment_documents.select(:id))
    end

    def with_failing_dependency_builder
      original_call = BuildShipmentDocumentDependencies.method(:call)
      BuildShipmentDocumentDependencies.define_singleton_method(:call) { |_shipment| raise ActiveRecord::RecordInvalid }
      yield
    ensure
      BuildShipmentDocumentDependencies.define_singleton_method(:call, original_call)
    end
end

class CreateShipmentWorkflowConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  teardown do
    cleanup_organization(@organization) if @organization
  end

  test "concurrent generation remains idempotent for one shipment" do
    suffix = SecureRandom.hex(4)
    @organization = create(:organization, name: "Concurrency Org #{suffix}", subdomain: "concurrency-org-#{suffix}")
    shipment = create(:shipment, purchase_order: create(:purchase_order, organization: @organization))

    errors = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          CreateShipmentWorkflow.call(Shipment.find(shipment.id))
        rescue => error
          errors << error
        end
      end
    end
    threads.each(&:join)

    assert errors.empty?, errors.size.times.map { errors.pop.message }.join(", ")
    assert_empty duplicate_document_instances(shipment)
    assert_empty duplicate_field_values(shipment)
    assert_empty duplicate_dependencies(shipment)
  end

  private

    def duplicate_document_instances(shipment)
      shipment.shipment_documents
              .group(:organization_id, :shipment_id, :document_template_id, :documentable_type, :documentable_id)
              .having("COUNT(*) > 1")
              .count
    end

    def duplicate_field_values(shipment)
      ShipmentDocumentFieldValue
        .joins(:shipment_document)
        .where(shipment_documents: { shipment_id: shipment.id })
        .group(:organization_id, :shipment_document_id, :document_field_definition_id)
        .having("COUNT(*) > 1")
        .count
    end

    def duplicate_dependencies(shipment)
      shipment.shipment_document_dependencies
              .group(:organization_id, :prerequisite_shipment_document_id, :shipment_document_id)
              .having("COUNT(*) > 1")
              .count
    end

    def cleanup_organization(organization)
      ActsAsTenant.with_tenant(organization) do
        organization.source_of_truth_checks.delete_all
        organization.shipment_document_dependencies.delete_all
        organization.shipment_document_field_values.delete_all
        organization.shipment_documents.delete_all
        organization.shipment_containers.delete_all
        organization.shipment_lots.delete_all
        organization.shipments.delete_all
        organization.purchase_order_lines.delete_all
        organization.purchase_orders.delete_all
        organization.master_agreements.delete_all
        organization.trading_partners.delete_all
        organization.source_of_truth_rule_targets.delete_all
        organization.source_of_truth_rules.delete_all
        organization.document_template_dependencies.delete_all
        organization.document_template_fields.delete_all
        organization.document_templates.delete_all
        organization.document_field_definitions.delete_all
        organization.workflow_phases.delete_all
        RolePermission.where(role_id: organization.roles.select(:id)).delete_all
        organization.roles.delete_all
      end
      organization.destroy
    end
end
