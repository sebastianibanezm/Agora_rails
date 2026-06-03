FactoryBot.define do
  factory :document_template_field do
    association :organization
    document_template { association :document_template, organization: organization }
    document_field_definition { association :document_field_definition, organization: organization }
    requirement { "required" }
  end
end
