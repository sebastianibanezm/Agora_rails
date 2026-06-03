class MasterAgreement < ApplicationRecord
  STATUSES = %w[draft active expired terminated].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :trading_partner
  has_many :purchase_orders, dependent: :restrict_with_error
  has_one_attached :contract_file

  has_paper_trail

  validates :agreement_number, presence: true, uniqueness: { scope: :organization_id }
  validates :name, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :trading_partner_belongs_to_organization

  private

    def trading_partner_belongs_to_organization
      return if trading_partner.blank? || organization_id.blank?
      return if trading_partner.organization_id == organization_id

      errors.add(:trading_partner, "must belong to the same organization")
    end
end
