FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    association :organization

    trait :owner  do name { "owner" }  end
    trait :admin  do name { "admin" }  end
    trait :member do name { "member" } end
  end
end
