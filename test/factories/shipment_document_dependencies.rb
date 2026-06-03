FactoryBot.define do
  factory :shipment_document_dependency do
    shipment_document
    organization { shipment_document.organization }
    prerequisite_shipment_document do
      association :shipment_document, organization: organization, shipment: shipment_document.shipment
    end
    status { "open" }
  end
end
