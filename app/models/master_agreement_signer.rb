class MasterAgreementSigner < ApplicationRecord
  include MasterAgreementExtractionRecord

  belongs_to :master_agreement_document

  validates :party_role, presence: true, inclusion: { in: MasterAgreementParty::PARTY_ROLES }
  validates :name, presence: true

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_document ]
    end
end
