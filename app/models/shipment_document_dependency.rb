class ShipmentDocumentDependency < ApplicationRecord
  STATUSES = %w[open satisfied waived].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :shipment_document
  belongs_to :prerequisite_shipment_document, class_name: "ShipmentDocument"

  has_paper_trail

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :prerequisite_shipment_document_id, uniqueness: { scope: %i[organization_id shipment_document_id] }
  validate :documents_belong_to_organization
  validate :documents_belong_to_same_workflow_context
  validate :cannot_depend_on_itself

  private

    def documents_belong_to_organization
      [ shipment_document, prerequisite_shipment_document ].compact.each do |document|
        next if document.organization_id == organization_id

        errors.add(:base, "shipment documents must belong to the same organization")
      end
    end

    def documents_belong_to_same_workflow_context
      return if shipment_document.blank? || prerequisite_shipment_document.blank?
      return if shipment_document.shipment_id == prerequisite_shipment_document.shipment_id
      return if document_belongs_to_shipment_workflow?(prerequisite_shipment_document, shipment_document.shipment)
      return if document_belongs_to_shipment_workflow?(shipment_document, prerequisite_shipment_document.shipment)

      errors.add(:base, "shipment documents must belong to the same workflow context")
    end

    def cannot_depend_on_itself
      return if shipment_document_id.blank? || prerequisite_shipment_document_id.blank?
      return unless shipment_document_id == prerequisite_shipment_document_id

      errors.add(:prerequisite_shipment_document, "cannot be the same document")
    end

    def document_belongs_to_shipment_workflow?(document, shipment)
      return false unless document&.agreement_level?
      return false if shipment&.master_agreement.blank?

      document.documentable_id == shipment.master_agreement.id
    end
end
