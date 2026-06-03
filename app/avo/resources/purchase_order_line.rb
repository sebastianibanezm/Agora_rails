class Avo::Resources::PurchaseOrderLine < Avo::BaseResource
  self.includes = [ :organization, :purchase_order ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :purchase_order, as: :belongs_to
    field :sku, as: :text
    field :product_description, as: :textarea
    field :hs_code, as: :text
    field :quantity, as: :number
    field :unit, as: :text
    field :unit_price, as: :number
    field :net_weight, as: :number
    field :packaging, as: :text
  end
end
