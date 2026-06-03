FactoryBot.define do
  factory :source_of_truth_rule do
    association :organization
    document_field_definition { association :document_field_definition, organization: organization }
    authoritative_document_template { association :document_template, organization: organization }
    logic { "Authoritative document wins when values differ." }
    failure_action { "correct_derivative" }
  end
end
