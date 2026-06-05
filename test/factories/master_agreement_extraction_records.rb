FactoryBot.define do
  factory :master_agreement_extracted_value do
    association :organization
    master_agreement { association :master_agreement, organization: organization }
    master_agreement_document { association :master_agreement_document, organization: organization, master_agreement: master_agreement }
    field_key { "payment_terms" }
    label { "Payment terms" }
    raw_value { "2% 15 Net 30 Days" }
    normalized_value { {} }
    review_status { "pending_review" }
  end

  factory :master_agreement_schedule do
    association :organization
    master_agreement { association :master_agreement, organization: organization }
    master_agreement_document { association :master_agreement_document, organization: organization, master_agreement: master_agreement, document_kind: "schedule" }
    title { "Frozen Fruit Schedule" }
    product_category { "FROZEN FRUIT/Frozen" }
    payment_terms { "2% 15 Net 30 Days" }
    lead_time_days { 15 }
    participating_companies { [ "ADUSA Distribution, LLC" ] }
    distributors { [ "C&S Wholesale Grocers, Inc." ] }
    pallet_requirements { [ "Grade A Hardwood" ] }
    review_status { "pending_review" }
  end

  factory :master_agreement_delivery_location do
    association :organization
    master_agreement { association :master_agreement, organization: organization }
    master_agreement_schedule { association :master_agreement_schedule, organization: organization, master_agreement: master_agreement }
    name { "Aberdeen Frozen Food Facility" }
    address { "1000 Old Philadelphia Rd" }
    city { "Aberdeen" }
    state_region { "MD" }
    postal_code { "21001" }
    review_status { "pending_review" }
  end

  factory :master_agreement_product_price_line do
    association :organization
    master_agreement { association :master_agreement, organization: organization }
    master_agreement_schedule { association :master_agreement_schedule, organization: organization, master_agreement: master_agreement }
    participating_company { "GIANT" }
    product_description { "NP ORG BERRY MEDLY 10Z" }
    case_pack { 8 }
    size { 10 }
    uom { "Ounce" }
    unit_cost_delivered { 1.76 }
    currency { "USD" }
    review_status { "pending_review" }
  end
end
