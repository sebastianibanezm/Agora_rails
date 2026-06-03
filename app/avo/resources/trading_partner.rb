class Avo::Resources::TradingPartner < Avo::BaseResource
  self.includes = [ :organization ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :name, as: :text
    field :legal_name, as: :text
    field :partner_type, as: :select, enum: TradingPartner::PARTNER_TYPES
    field :tax_identifier, as: :text
    field :country, as: :text
    field :email, as: :text
    field :phone, as: :text
    field :address, as: :textarea
    field :active, as: :boolean
    field :master_agreements, as: :has_many
    field :purchase_orders, as: :has_many
  end
end
