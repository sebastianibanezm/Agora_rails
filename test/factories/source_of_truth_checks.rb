FactoryBot.define do
  factory :source_of_truth_check do
    shipment
    organization { shipment.organization }
    source_of_truth_rule { organization.source_of_truth_rules.first }
    authoritative_shipment_document { shipment.shipment_documents.find_by!(document_template: source_of_truth_rule.authoritative_document_template) }
    target_shipment_document { shipment.shipment_documents.where.not(id: authoritative_shipment_document.id).first }
    document_field_definition { source_of_truth_rule.document_field_definition }
    status { "matched" }
    expected_value { "value" }
    actual_value { "value" }
    failure_action { source_of_truth_rule.failure_action }
  end
end
