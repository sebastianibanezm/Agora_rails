FactoryBot.define do
  factory :shipment_document do
    shipment
    organization { shipment.organization }
    document_template { organization.document_templates.find_by!(code: "shipping_instruction") }
    documentable { shipment }
    status { "pending" }
  end
end
