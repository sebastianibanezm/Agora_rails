class Avo::Resources::WorkflowPhase < Avo::BaseResource
  self.includes = [ :organization, :document_templates ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :position, as: :number
    field :code, as: :text
    field :name, as: :text
    field :owner_role, as: :text
    field :timeline_start, as: :text
    field :timeline_end, as: :text
    field :description, as: :textarea
    field :document_templates, as: :has_many
  end
end
