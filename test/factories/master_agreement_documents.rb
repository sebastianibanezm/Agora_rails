FactoryBot.define do
  factory :master_agreement_document do
    association :organization
    master_agreement { association :master_agreement, organization: organization }
    title { "Private Label Master Supply Agreement" }
    document_kind { "agreement" }
    extraction_status { "not_started" }
  end
end
