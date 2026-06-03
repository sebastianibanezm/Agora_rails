FactoryBot.define do
  factory :workflow_phase do
    association :organization
    sequence(:position) { |n| n + 100 }
    sequence(:code) { |n| "phase_#{n}" }
    sequence(:name) { |n| "Phase #{n}" }
    owner_role { "COMEX" }
    timeline_start { "T-7" }
    timeline_end { "T-3" }
  end
end
