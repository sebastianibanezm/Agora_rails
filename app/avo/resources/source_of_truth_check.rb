class Avo::Resources::SourceOfTruthCheck < Avo::BaseResource
  self.includes = [ :organization, :shipment, :source_of_truth_rule, :authoritative_shipment_document, :target_shipment_document, :document_field_definition ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :shipment, as: :belongs_to
    field :source_of_truth_rule, as: :belongs_to
    field :authoritative_shipment_document, as: :belongs_to
    field :target_shipment_document, as: :belongs_to
    field :document_field_definition, as: :belongs_to
    field :status, as: :select, enum: SourceOfTruthCheck::STATUSES
    field :expected_value, as: :code
    field :actual_value, as: :code
    field :failure_action, as: :select, enum: SourceOfTruthRule::FAILURE_ACTIONS
  end
end
