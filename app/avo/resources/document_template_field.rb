class Avo::Resources::DocumentTemplateField < Avo::BaseResource
  self.includes = [ :organization, :document_template, :document_field_definition ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :document_template, as: :belongs_to
    field :document_field_definition, as: :belongs_to
    field :requirement, as: :select, enum: DocumentTemplateField::REQUIREMENTS
    field :notes, as: :textarea
  end
end
