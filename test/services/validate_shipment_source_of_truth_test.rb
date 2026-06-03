require "test_helper"

class ValidateShipmentSourceOfTruthTest < ActiveSupport::TestCase
  test "persists mismatch checks without mutating target values" do
    shipment = create(:shipment)
    rule = shipment.organization.source_of_truth_rules.find_by!(
      document_field_definition: shipment.organization.document_field_definitions.find_by!(key: "consignee")
    )
    authoritative = shipment.shipment_documents.find_by!(document_template: rule.authoritative_document_template)
    target = shipment.shipment_documents.find_by!(document_template: rule.source_of_truth_rule_targets.first.document_template)
    field = rule.document_field_definition

    authoritative.shipment_document_field_values.find_by!(document_field_definition: field).update!(value: "Buyer A", raw_value: "Buyer A")
    target.shipment_document_field_values.find_by!(document_field_definition: field).update!(value: "Buyer B", raw_value: "Buyer B")

    ValidateShipmentSourceOfTruth.call(shipment)

    check = shipment.source_of_truth_checks.find_by!(source_of_truth_rule: rule, target_shipment_document: target)
    assert_equal "mismatch", check.status
    assert_equal "Buyer B", target.shipment_document_field_values.find_by!(document_field_definition: field).value
  end
end
