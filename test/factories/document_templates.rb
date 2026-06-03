FactoryBot.define do
  factory :document_template do
    association :organization
    workflow_phase { association :workflow_phase, organization: organization }
    sequence(:code) { |n| "document_template_#{n}" }
    sequence(:name) { |n| "Document Template #{n}" }
    step_number { nil }
    timeline { "T-7" }
    document_type { "derivado" }
    category { "documento" }
    obligation { "obligatorio" }
    criticality { "alto" }
    grain { "embarque" }
    destinations { [] }
    generator_roles { [ "COMEX" ] }
    receiver_roles { [ "Agente de Aduanas" ] }
    active { true }
  end
end
