require "test_helper"

class BuildShipmentDocumentDependenciesTest < ActiveSupport::TestCase
  test "creates runtime dependency edges from template dependencies" do
    shipment = create(:shipment)
    runtime_dependencies_for(shipment).destroy_all

    assert_changes -> { shipment.shipment_document_dependencies.count }, from: 0 do
      BuildShipmentDocumentDependencies.call(shipment)
    end
  end

  test "is idempotent" do
    shipment = create(:shipment)
    BuildShipmentDocumentDependencies.call(shipment)
    count = shipment.shipment_document_dependencies.count

    assert_no_changes -> { shipment.shipment_document_dependencies.count } do
      BuildShipmentDocumentDependencies.call(shipment)
    end

    assert_equal count, shipment.shipment_document_dependencies.count
  end

  test "marks edges satisfied when prerequisite is approved or waived" do
    shipment = create(:shipment)
    existing_dependency = shipment.shipment_document_dependencies.first
    prerequisite = existing_dependency.prerequisite_shipment_document
    dependent = existing_dependency.shipment_document
    runtime_dependencies_for(shipment).destroy_all

    prerequisite.update!(status: "approved")

    BuildShipmentDocumentDependencies.call(shipment)

    assert shipment.shipment_document_dependencies.where(
      shipment_document: dependent,
      prerequisite_shipment_document: prerequisite,
      status: "satisfied"
    ).exists?
  end

  test "preserves waived runtime dependency status" do
    shipment = create(:shipment)
    dependency = shipment.shipment_document_dependencies.first
    dependency.update!(status: "waived")

    BuildShipmentDocumentDependencies.call(shipment)

    assert_equal "waived", dependency.reload.status
  end

  test "skips self dependencies" do
    shipment = create(:shipment)
    runtime_dependencies_for(shipment).destroy_all
    template = shipment.organization.document_templates.find_by!(code: "shipping_instruction")
    template_dependency = build(:document_template_dependency,
                                organization: shipment.organization,
                                prerequisite_document_template: template,
                                dependent_document_template: template)
    template_dependency.save!(validate: false)

    BuildShipmentDocumentDependencies.call(shipment)

    document = shipment.shipment_documents.find_by!(document_template: template)
    assert_not shipment.shipment_document_dependencies.exists?(
      shipment_document: document,
      prerequisite_shipment_document: document
    )
  end

  private

    def runtime_dependencies_for(shipment)
      ShipmentDocumentDependency.where(shipment_document_id: shipment.shipment_documents.select(:id))
    end
end
