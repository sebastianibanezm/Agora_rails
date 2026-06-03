class Avo::Resources::SourceOfTruthRule < Avo::BaseResource
  self.includes = [ :organization, :document_field_definition, :authoritative_document_template ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :document_field_definition, as: :belongs_to
    field :authoritative_document_template, as: :belongs_to
    field :logic, as: :textarea
    field :failure_action, as: :select, enum: SourceOfTruthRule::FAILURE_ACTIONS
    field :source_of_truth_rule_targets, as: :has_many
    field :source_of_truth_checks, as: :has_many
  end
end
