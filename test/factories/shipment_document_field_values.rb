FactoryBot.define do
  factory :shipment_document_field_value do
    shipment_document
    organization { shipment_document.organization }
    document_field_definition { organization.document_field_definitions.first }
    value { "value" }
    raw_value { "value" }
    source { "manual" }
    confirmed { false }
  end
end
