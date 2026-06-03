FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    first_name { "Test" }
    last_name  { "User" }
    superadmin { false }
    association :organization
    role { nil }

    trait :superadmin do
      superadmin { true }
      organization { nil }
      role { nil }
    end

    trait :with_role do
      role { association :role, organization: organization }
    end
  end
end
