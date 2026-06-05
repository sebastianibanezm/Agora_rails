class Avo::Resources::ShipmentContainer < Avo::BaseResource
  self.includes = [ :organization, :shipment, :shipment_documents ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :shipment, as: :belongs_to
    field :container_number, as: :text
    field :seal_number, as: :text
    field :vgm, as: :number
    field :gross_weight, as: :number
    field :net_weight, as: :number
    field :package_count, as: :number
    field :shipment_documents, as: :has_many
  end
end
