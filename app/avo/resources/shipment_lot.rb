class Avo::Resources::ShipmentLot < Avo::BaseResource
  self.includes = [ :organization, :shipment, :shipment_documents ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :shipment, as: :belongs_to
    field :lot_number, as: :text
    field :sku, as: :text
    field :product_description, as: :textarea
    field :quantity, as: :number
    field :net_weight, as: :number
    field :shipment_documents, as: :has_many
  end
end
