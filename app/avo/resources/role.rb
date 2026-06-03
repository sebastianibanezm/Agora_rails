class Avo::Resources::Role < Avo::BaseResource
  self.includes = [:organization, :permissions]

  def fields
    field :id, as: :id
    field :name, as: :text
    field :description, as: :textarea
    field :organization, as: :belongs_to
    field :permissions, as: :has_many, through: :role_permissions
    field :users, as: :has_many
  end
end
