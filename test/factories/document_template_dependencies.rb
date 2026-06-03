FactoryBot.define do
  factory :document_template_dependency do
    association :organization
    prerequisite_document_template { association :document_template, organization: organization }
    dependent_document_template { association :document_template, organization: organization }
  end
end
