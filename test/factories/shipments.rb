FactoryBot.define do
  factory :shipment do
    purchase_order
    organization { purchase_order.organization }
    sequence(:shipment_number) { |n| "SHP-#{n}" }
    status { "planning" }
    destination_country { purchase_order.destination_country }
    incoterm { purchase_order.incoterm }
    pol { "CLSAI" }
    pod { "CNSHA" }
  end
end
