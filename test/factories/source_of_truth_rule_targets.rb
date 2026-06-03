FactoryBot.define do
  factory :source_of_truth_rule_target do
    association :organization
    source_of_truth_rule { association :source_of_truth_rule, organization: organization }
    document_template { association :document_template, organization: organization }
  end
end
