FactoryBot.define do
  factory :organization do
    sequence(:name)      { |n| "Org #{n}" }
    sequence(:subdomain) { |n| "org-#{n}" }
    plan { "starter" }
    features { {} }
  end
end
