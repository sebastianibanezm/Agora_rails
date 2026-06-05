class MasterAgreementClause < ApplicationRecord
  include MasterAgreementExtractionRecord

  belongs_to :master_agreement_document

  validates :section_number, :title, presence: true
  validate :obligations_are_array

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_document ]
    end

    def obligations_are_array
      return if obligations.is_a?(Array)

      errors.add(:obligations, "must be an array")
    end
end
