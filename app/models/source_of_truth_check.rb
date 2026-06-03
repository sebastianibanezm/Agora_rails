class SourceOfTruthCheck < ApplicationRecord
  STATUSES = %w[pending matched mismatch waived].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :shipment
  belongs_to :source_of_truth_rule
  belongs_to :authoritative_shipment_document, class_name: "ShipmentDocument"
  belongs_to :target_shipment_document, class_name: "ShipmentDocument"
  belongs_to :document_field_definition

  has_paper_trail

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :failure_action, presence: true, inclusion: { in: SourceOfTruthRule::FAILURE_ACTIONS }
  validates :source_of_truth_rule_id, uniqueness: {
    scope: %i[organization_id shipment_id authoritative_shipment_document_id target_shipment_document_id]
  }
  validate :records_belong_to_organization
  validate :documents_belong_to_shipment

  private

    def records_belong_to_organization
      [ shipment, source_of_truth_rule, authoritative_shipment_document, target_shipment_document, document_field_definition ].compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end

    def documents_belong_to_shipment
      [ authoritative_shipment_document, target_shipment_document ].compact.each do |document|
        next if shipment_id.blank? || document.shipment_id == shipment_id

        errors.add(:base, "shipment documents must belong to the checked shipment")
      end
    end
end
