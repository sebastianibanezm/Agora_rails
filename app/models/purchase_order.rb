class PurchaseOrder < ApplicationRecord
  STATUSES = %w[draft received validated in_production shipping completed cancelled].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :trading_partner
  belongs_to :master_agreement
  has_many :purchase_order_lines, dependent: :destroy
  has_many :shipments, dependent: :restrict_with_error
  has_one_attached :purchase_order_file

  has_paper_trail

  validates :po_number, presence: true, uniqueness: { scope: :organization_id }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :records_belong_to_organization
  validate :master_agreement_matches_trading_partner

  private

    def records_belong_to_organization
      [ trading_partner, master_agreement ].compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end

    def master_agreement_matches_trading_partner
      return if trading_partner.blank? || master_agreement.blank?
      return if master_agreement.trading_partner_id == trading_partner_id

      errors.add(:master_agreement, "must belong to the same trading partner")
    end
end
