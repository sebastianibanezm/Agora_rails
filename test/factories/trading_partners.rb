FactoryBot.define do
  factory :trading_partner do
    association :organization
    sequence(:name) { |n| "Buyer #{n}" }
    sequence(:legal_name) { |n| "Buyer Legal #{n}" }
    partner_type { "buyer" }
    country { "Chile" }
    active { true }
  end
end
