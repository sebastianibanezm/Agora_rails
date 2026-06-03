class Avo::Resources::Shipment < Avo::BaseResource
  self.includes = [ :organization, :purchase_order ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :purchase_order, as: :belongs_to
    field :shipment_number, as: :text
    field :status, as: :select, enum: Shipment::STATUSES
    field :etd, as: :date_time
    field :eta, as: :date_time
    field :pol, as: :text
    field :pod, as: :text
    field :booking_number, as: :text
    field :vessel, as: :text
    field :voyage, as: :text
    field :incoterm, as: :text
    field :destination_country, as: :text
    field :notes, as: :textarea
    field :shipment_lots, as: :has_many
    field :shipment_containers, as: :has_many
    field :shipment_documents, as: :has_many
    field :source_of_truth_checks, as: :has_many
  end
end
