class Avo::Resources::Organization < Avo::BaseResource
  self.includes = [:users]

  def fields
    field :id, as: :id
    field :name, as: :text
    field :subdomain, as: :text
    field :plan, as: :select, enum: Organization::PLANS
    field :features, as: :code
    field :users, as: :has_many
    field :trading_partners, as: :has_many
    field :master_agreements, as: :has_many
    field :purchase_orders, as: :has_many
    field :shipments, as: :has_many
    field :shipment_documents, as: :has_many
    field :workflow_phases, as: :has_many
    field :document_templates, as: :has_many
    field :document_field_definitions, as: :has_many
    field :source_of_truth_rules, as: :has_many
    field :source_of_truth_checks, as: :has_many
  end
end
