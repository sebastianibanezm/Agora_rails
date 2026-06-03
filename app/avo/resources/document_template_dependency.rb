class Avo::Resources::DocumentTemplateDependency < Avo::BaseResource
  self.includes = [ :organization, :prerequisite_document_template, :dependent_document_template ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :prerequisite_document_template, as: :belongs_to
    field :dependent_document_template, as: :belongs_to
    field :condition, as: :textarea
  end
end
