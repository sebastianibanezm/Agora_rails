class TradingPartner < ApplicationRecord
  PARTNER_TYPES = %w[buyer consignee notify_party forwarder carrier customs_broker bank other].freeze

  acts_as_tenant :organization

  belongs_to :organization
  has_many :master_agreements, dependent: :restrict_with_error
  has_many :purchase_orders, dependent: :restrict_with_error

  has_paper_trail

  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :legal_name, uniqueness: { scope: :organization_id }, allow_blank: true
  validates :partner_type, presence: true, inclusion: { in: PARTNER_TYPES }
end
