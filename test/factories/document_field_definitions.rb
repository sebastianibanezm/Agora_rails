FactoryBot.define do
  factory :document_field_definition do
    association :organization
    sequence(:key) { |n| "field_#{n}" }
    sequence(:name) { |n| "Field #{n}" }
    value_type { "string" }
  end
end
