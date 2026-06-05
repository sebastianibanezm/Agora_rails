class MasterAgreementExtractedValue < ApplicationRecord
  include MasterAgreementExtractionRecord

  belongs_to :master_agreement_document
  belongs_to :reviewed_by, class_name: "User", optional: true

  validates :field_key, presence: true,
                        format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, and underscores" }
  validates :label, presence: true

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_document ]
    end
end
