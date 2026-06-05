class MasterAgreementParty < ApplicationRecord
  include MasterAgreementExtractionRecord

  PARTY_ROLES = %w[customer vendor participating_company distributor other].freeze

  belongs_to :master_agreement_document, optional: true

  validates :party_role, presence: true, inclusion: { in: PARTY_ROLES }
  validates :name, presence: true

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_document ]
    end
end
