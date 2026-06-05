class Avo::Resources::ShipmentDocument < Avo::BaseResource
  self.includes = [ :organization, :shipment, :document_template, :shipment_document_field_values, :incoming_dependencies, :outgoing_dependencies ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :shipment, as: :belongs_to
    field :document_template, as: :belongs_to
    field :documentable_type, as: :text
    field :documentable_id, as: :number
    field :status, as: :select, enum: ShipmentDocument::STATUSES
    field :due_on, as: :date
    field :completed_at, as: :date_time
    field :assigned_role, as: :text
    field :waiver_reason, as: :textarea
    field :shipment_document_field_values, as: :has_many
    field :incoming_dependencies, as: :has_many
    field :outgoing_dependencies, as: :has_many
  end
end
