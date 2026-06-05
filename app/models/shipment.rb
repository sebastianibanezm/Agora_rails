class Shipment < ApplicationRecord
  STATUSES = %w[planning documents_pending ready_to_ship shipped post_zarpe closed cancelled].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :purchase_order
  has_many :shipment_lots, dependent: :destroy
  has_many :shipment_containers, dependent: :destroy
  has_many :shipment_documents, dependent: :destroy
  has_many :shipment_document_dependencies, through: :shipment_documents, source: :incoming_dependencies
  has_many :source_of_truth_checks, dependent: :destroy

  has_paper_trail

  after_create :create_workflow

  validates :shipment_number, presence: true, uniqueness: { scope: :organization_id }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :purchase_order_belongs_to_organization

  def trading_partner
    purchase_order&.trading_partner
  end

  def master_agreement
    purchase_order&.master_agreement
  end

  def workflow_documents
    return shipment_documents unless master_agreement

    organization.shipment_documents
                .where(shipment_id: id)
                .or(organization.shipment_documents.where(documentable: master_agreement))
  end

  private

    def purchase_order_belongs_to_organization
      return if purchase_order.blank? || organization_id.blank?
      return if purchase_order.organization_id == organization_id

      errors.add(:purchase_order, "must belong to the same organization")
    end

    def create_workflow
      CreateShipmentWorkflow.call!(self)
    end
end
