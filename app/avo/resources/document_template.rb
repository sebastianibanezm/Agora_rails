class Avo::Resources::DocumentTemplate < Avo::BaseResource
  self.includes = [ :organization, :workflow_phase ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :workflow_phase, as: :belongs_to
    field :step_number, as: :number
    field :code, as: :text
    field :name, as: :text
    field :timeline, as: :text
    field :document_type, as: :select, enum: DocumentTemplate::DOCUMENT_TYPES
    field :category, as: :select, enum: DocumentTemplate::CATEGORIES
    field :obligation, as: :select, enum: DocumentTemplate::OBLIGATIONS
    field :criticality, as: :select, enum: DocumentTemplate::CRITICALITIES
    field :grain, as: :select, enum: DocumentTemplate::GRAINS
    field :destinations, as: :code
    field :generator_roles, as: :code
    field :receiver_roles, as: :code
    field :description, as: :textarea
    field :current_state, as: :textarea
    field :as_is_risk, as: :textarea
    field :source_of_truth_fields, as: :textarea
    field :key_data, as: :textarea
    field :active, as: :boolean
    field :incoming_dependencies, as: :has_many
    field :outgoing_dependencies, as: :has_many
    field :document_template_fields, as: :has_many
    field :shipment_documents, as: :has_many
    field :source_of_truth_rules, as: :has_many
    field :source_of_truth_rule_targets, as: :has_many
  end
end
