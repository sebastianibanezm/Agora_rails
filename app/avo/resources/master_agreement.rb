class Avo::Resources::MasterAgreement < Avo::BaseResource
  self.includes = [ :organization, :trading_partner, :purchase_orders, :shipment_documents ]

  def fields
    field :id, as: :id
    field :organization, as: :belongs_to
    field :trading_partner, as: :belongs_to
    field :agreement_number, as: :text
    field :name, as: :text
    field :status, as: :select, enum: MasterAgreement::STATUSES
    field :effective_on, as: :date
    field :expires_on, as: :date
    field :incoterm, as: :text
    field :payment_terms, as: :text
    field :currency, as: :text
    field :notes, as: :textarea
    field :contract_file, as: :file
    field :purchase_orders, as: :has_many
  end
end
