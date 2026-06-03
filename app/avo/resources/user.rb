class Avo::Resources::User < Avo::BaseResource
  self.includes = [:organization, :role]

  def fields
    field :id, as: :id
    field :first_name, as: :text
    field :last_name, as: :text
    field :email_address, as: :text
    field :password, as: :password, only_on: %i[new edit]
    field :superadmin, as: :boolean
    field :organization, as: :belongs_to
    field :role, as: :belongs_to
  end
end
