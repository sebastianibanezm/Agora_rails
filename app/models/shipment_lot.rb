class ShipmentLot < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :shipment
  has_many :shipment_documents, as: :documentable, dependent: :destroy

  has_paper_trail

  after_create :refresh_workflow

  validates :lot_number, presence: true, uniqueness: { scope: %i[organization_id shipment_id] }
  validate :shipment_belongs_to_organization

  private

    def shipment_belongs_to_organization
      return if shipment.blank? || organization_id.blank?
      return if shipment.organization_id == organization_id

      errors.add(:shipment, "must belong to the same organization")
    end

    def refresh_workflow
      CreateShipmentWorkflow.call!(shipment)
    end
end
