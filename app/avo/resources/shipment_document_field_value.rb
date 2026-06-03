class Avo::Resources::ShipmentDocumentFieldValue < Avo::BaseResource
  self.includes = [ :organization, :shipment_document, :document_field_definition ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :shipment_document, as: :belongs_to
    field :document_field_definition, as: :belongs_to
    field :value, as: :code
    field :raw_value, as: :text
    field :source, as: :select, enum: ShipmentDocumentFieldValue::SOURCES
    field :confirmed, as: :boolean
  end
end
