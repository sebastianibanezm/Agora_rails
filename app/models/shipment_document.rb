class ShipmentDocument < ApplicationRecord
  STATUSES = %w[not_started blocked pending in_review approved rejected waived].freeze
  DOCUMENTABLE_TYPES = %w[Shipment MasterAgreement PurchaseOrder PurchaseOrderLine ShipmentLot ShipmentContainer].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :shipment
  belongs_to :document_template
  belongs_to :documentable, polymorphic: true

  has_many :shipment_document_field_values, dependent: :destroy
  has_many :document_field_definitions, through: :shipment_document_field_values
  has_many :incoming_dependencies,
           class_name: "ShipmentDocumentDependency",
           foreign_key: :shipment_document_id,
           inverse_of: :shipment_document,
           dependent: :destroy
  has_many :outgoing_dependencies,
           class_name: "ShipmentDocumentDependency",
           foreign_key: :prerequisite_shipment_document_id,
           inverse_of: :prerequisite_shipment_document,
           dependent: :destroy
  has_many_attached :files

  has_paper_trail

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :documentable_type, presence: true, inclusion: { in: DOCUMENTABLE_TYPES }
  validates :document_template_id, uniqueness: {
    scope: %i[organization_id shipment_id documentable_type documentable_id]
  }, unless: :agreement_level?
  validates :document_template_id, uniqueness: {
    scope: %i[organization_id documentable_type documentable_id]
  }, if: :agreement_level?
  validate :records_belong_to_organization
  validate :documentable_belongs_to_shipment

  def approved_or_waived?
    status.in?(%w[approved waived])
  end

  def agreement_level?
    documentable_type == "MasterAgreement"
  end

  private

    def records_belong_to_organization
      [ shipment, document_template ].compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end

    def documentable_belongs_to_shipment
      return if shipment.blank?
      return unless documentable_type.in?(DOCUMENTABLE_TYPES)
      return if documentable.blank?

      case documentable
      when Shipment
        errors.add(:documentable, "must be this shipment") unless documentable.id == shipment_id
      when MasterAgreement
        errors.add(:documentable, "must belong to this shipment hierarchy") unless documentable.id == shipment.master_agreement&.id
      when PurchaseOrder
        errors.add(:documentable, "must belong to this shipment hierarchy") unless documentable.id == shipment.purchase_order_id
      when PurchaseOrderLine
        errors.add(:documentable, "must belong to this shipment hierarchy") unless documentable.purchase_order_id == shipment.purchase_order_id
      when ShipmentLot, ShipmentContainer
        errors.add(:documentable, "must belong to this shipment") unless documentable.shipment_id == shipment_id
      else
        errors.add(:documentable, "is not supported")
      end
    end
end
