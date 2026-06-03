FactoryBot.define do
  factory :purchase_order do
    association :organization
    trading_partner { association :trading_partner, organization: organization }
    master_agreement { association :master_agreement, organization: organization, trading_partner: trading_partner }
    sequence(:po_number) { |n| "PO-#{n}" }
    status { "received" }
    destination_country { "China" }
    consignee_name { "Consignee SA" }
    notify_party_name { "Notify SA" }
    incoterm { "FOB" }
    currency { "USD" }
    total_amount { 10_000 }
  end
end
