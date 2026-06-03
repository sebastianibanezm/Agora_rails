class ShipmentDocumentFieldValue < ApplicationRecord
  SOURCES = %w[manual derived imported ocr].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :shipment_document
  belongs_to :document_field_definition

  has_paper_trail

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :document_field_definition_id, uniqueness: { scope: %i[organization_id shipment_document_id] }
  validate :records_belong_to_organization

  private

    def records_belong_to_organization
      [ shipment_document, document_field_definition ].compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end
end
