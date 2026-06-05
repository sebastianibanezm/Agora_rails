require "test_helper"

class OperationalWorkflowModelsTest < ActiveSupport::TestCase
  test "trading partner validates organization scoped names and partner type" do
    org = create(:organization)
    create(:trading_partner, organization: org, name: "Buyer", legal_name: "Buyer Legal")

    duplicate = build(:trading_partner, organization: org, name: "Buyer", legal_name: "Other Legal")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    duplicate.name = "Other Buyer"
    duplicate.partner_type = "unknown"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:partner_type], "is not included in the list"
  end

  test "purchase order rejects mismatched master agreement and trading partner" do
    org = create(:organization)
    buyer = create(:trading_partner, organization: org)
    other_buyer = create(:trading_partner, organization: org)
    agreement = create(:master_agreement, organization: org, trading_partner: other_buyer)

    purchase_order = build(:purchase_order, organization: org, trading_partner: buyer, master_agreement: agreement)

    assert_not purchase_order.valid?
    assert_includes purchase_order.errors[:master_agreement], "must belong to the same trading partner"
  end

  test "shipment rejects purchase orders from another organization" do
    org = create(:organization)
    other_purchase_order = create(:purchase_order, organization: create(:organization))

    shipment = build(:shipment, organization: org, purchase_order: other_purchase_order)

    assert_not shipment.valid?
    assert_includes shipment.errors[:purchase_order], "must belong to the same organization"
  end

  test "shipment document enforces one instance per template and documentable" do
    shipment = create(:shipment)
    document = shipment.shipment_documents.find_by!(document_template: shipment.organization.document_templates.find_by!(code: "shipping_instruction"))

    duplicate = build(:shipment_document,
                      organization: shipment.organization,
                      shipment: shipment,
                      document_template: document.document_template,
                      documentable: shipment)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:document_template_id], "has already been taken"
  end

  test "shipment document enforces one agreement-level document per agreement and template" do
    organization = create(:organization)
    trading_partner = create(:trading_partner, organization: organization)
    agreement = create(:master_agreement, organization: organization, trading_partner: trading_partner)
    first_shipment = create(:shipment, purchase_order: create(:purchase_order, organization: organization, trading_partner: trading_partner, master_agreement: agreement))
    second_shipment = create(:shipment, purchase_order: create(:purchase_order, organization: organization, trading_partner: trading_partner, master_agreement: agreement))
    template = organization.document_templates.find_by!(code: "master_agreement")

    duplicate = build(:shipment_document,
                      organization: organization,
                      shipment: second_shipment,
                      document_template: template,
                      documentable: agreement)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:document_template_id], "has already been taken"
    assert_equal 1, agreement.shipment_documents.where(document_template: template).count
    assert first_shipment.workflow_documents.exists?(document_template: template)
    assert second_shipment.workflow_documents.exists?(document_template: template)
  end

  test "shipment document rejects documentables outside the shipment hierarchy" do
    shipment = create(:shipment)
    other_line = create(:purchase_order_line, purchase_order: create(:purchase_order, organization: shipment.organization))
    template = shipment.organization.document_templates.find_by!(code: "product_spec")

    document = build(:shipment_document,
                     organization: shipment.organization,
                     shipment: shipment,
                     document_template: template,
                     documentable: other_line)

    assert_not document.valid?
    assert_includes document.errors[:documentable], "must belong to this shipment hierarchy"
  end

  test "shipment document rejects unsupported documentable types" do
    shipment = create(:shipment)
    template = shipment.organization.document_templates.find_by!(code: "shipping_instruction")

    document = build(:shipment_document,
                     organization: shipment.organization,
                     shipment: shipment,
                     document_template: template,
                     documentable_type: "Organization",
                     documentable_id: shipment.organization_id)

    assert_not document.valid?
    assert_includes document.errors[:documentable_type], "is not included in the list"
  end
end
