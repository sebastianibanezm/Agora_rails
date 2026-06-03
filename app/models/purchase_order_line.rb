class PurchaseOrderLine < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :purchase_order

  has_paper_trail

  validates :sku, presence: true
  validate :purchase_order_belongs_to_organization

  private

    def purchase_order_belongs_to_organization
      return if purchase_order.blank? || organization_id.blank?
      return if purchase_order.organization_id == organization_id

      errors.add(:purchase_order, "must belong to the same organization")
    end
end
