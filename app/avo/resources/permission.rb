class Avo::Resources::Permission < Avo::BaseResource
  self.includes = [:roles]

  def fields
    field :id, as: :id
    field :resource, as: :text
    field :action, as: :text
    field :roles, as: :has_many, through: :role_permissions
  end
end
