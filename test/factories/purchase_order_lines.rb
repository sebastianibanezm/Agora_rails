FactoryBot.define do
  factory :purchase_order_line do
    purchase_order
    organization { purchase_order.organization }
    sequence(:sku) { |n| "SKU-#{n}" }
    product_description { "Walnuts" }
    hs_code { "0802.32" }
    quantity { 100 }
    unit { "boxes" }
    unit_price { 10 }
    net_weight { 1_000 }
  end
end
