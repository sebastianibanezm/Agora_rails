FactoryBot.define do
  factory :shipment_lot do
    shipment
    organization { shipment.organization }
    sequence(:lot_number) { |n| "LOT-#{n}" }
    sku { "SKU-1" }
    product_description { "Walnuts" }
    quantity { 100 }
    net_weight { 1_000 }
  end
end
