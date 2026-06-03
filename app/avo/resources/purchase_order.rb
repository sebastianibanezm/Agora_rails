class Avo::Resources::PurchaseOrder < Avo::BaseResource
  self.includes = [ :organization, :trading_partner, :master_agreement ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :trading_partner, as: :belongs_to
    field :master_agreement, as: :belongs_to
    field :po_number, as: :text
    field :status, as: :select, enum: PurchaseOrder::STATUSES
    field :issued_on, as: :date
    field :required_ship_on, as: :date
    field :destination_country, as: :text
    field :consignee_name, as: :text
    field :notify_party_name, as: :text
    field :incoterm, as: :text
    field :currency, as: :text
    field :total_amount, as: :number
    field :notes, as: :textarea
    field :purchase_order_file, as: :file
    field :purchase_order_lines, as: :has_many
    field :shipments, as: :has_many
  end
end
