class MasterAgreementContact < ApplicationRecord
  include MasterAgreementExtractionRecord

  CONTACT_TYPES = %w[notice copy emergency recall category_manager qa legal other].freeze
  PARTY_ROLES = MasterAgreementParty::PARTY_ROLES

  belongs_to :master_agreement_document, optional: true

  validates :contact_type, presence: true, inclusion: { in: CONTACT_TYPES }
  validates :party_role, inclusion: { in: PARTY_ROLES }, allow_blank: true
  validate :has_contact_detail

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_document ]
    end

    def has_contact_detail
      return if [ name, title, phone, email, address ].any?(&:present?)

      errors.add(:base, "must include at least one contact detail")
    end
end
