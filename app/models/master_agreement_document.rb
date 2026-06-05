class MasterAgreementDocument < ApplicationRecord
  DOCUMENT_KINDS = %w[agreement schedule exhibit certificate].freeze
  EXTRACTION_STATUSES = %w[not_started pending processing succeeded failed needs_review].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :master_agreement
  belongs_to :reviewed_by, class_name: "User", optional: true

  has_one_attached :file

  has_many :master_agreement_extracted_values, dependent: :destroy
  has_many :master_agreement_parties, dependent: :destroy
  has_many :master_agreement_contacts, dependent: :destroy
  has_many :master_agreement_signers, dependent: :destroy
  has_many :master_agreement_schedules, dependent: :destroy
  has_many :master_agreement_clauses, dependent: :destroy

  has_paper_trail

  validates :document_kind, presence: true, inclusion: { in: DOCUMENT_KINDS }
  validates :extraction_status, presence: true, inclusion: { in: EXTRACTION_STATUSES }
  validates :title, presence: true
  validate :master_agreement_belongs_to_organization

  def reviewed?
    reviewed_at.present?
  end

  private

    def master_agreement_belongs_to_organization
      return if master_agreement.blank? || organization_id.blank?
      return if master_agreement.organization_id == organization_id

      errors.add(:master_agreement, "must belong to the same organization")
    end
end
