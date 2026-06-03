class Avo::Resources::DocumentFieldDefinition < Avo::BaseResource
  self.includes = [ :organization, :document_templates ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :key, as: :text
    field :name, as: :text
    field :value_type, as: :select, enum: DocumentFieldDefinition::VALUE_TYPES
    field :description, as: :textarea
    field :document_template_fields, as: :has_many
    field :source_of_truth_rules, as: :has_many
    field :shipment_document_field_values, as: :has_many
    field :source_of_truth_checks, as: :has_many
  end
end
