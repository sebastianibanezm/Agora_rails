class Avo::Resources::ShipmentDocumentDependency < Avo::BaseResource
  self.includes = [ :organization, :shipment_document, :prerequisite_shipment_document ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :shipment_document, as: :belongs_to
    field :prerequisite_shipment_document, as: :belongs_to
    field :status, as: :select, enum: ShipmentDocumentDependency::STATUSES
  end
end
