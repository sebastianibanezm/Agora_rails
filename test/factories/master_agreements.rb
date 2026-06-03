FactoryBot.define do
  factory :master_agreement do
    association :organization
    trading_partner { association :trading_partner, organization: organization }
    sequence(:agreement_number) { |n| "MA-#{n}" }
    sequence(:name) { |n| "Master Agreement #{n}" }
    status { "active" }
    incoterm { "FOB" }
    currency { "USD" }
  end
end
