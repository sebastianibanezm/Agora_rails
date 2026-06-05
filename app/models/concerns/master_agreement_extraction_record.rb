module MasterAgreementExtractionRecord
  extend ActiveSupport::Concern

  REVIEW_STATUSES = %w[pending_review confirmed rejected].freeze

  included do
    acts_as_tenant :organization

    belongs_to :organization
    belongs_to :master_agreement

    has_paper_trail

    validates :review_status, presence: true, inclusion: { in: REVIEW_STATUSES }, if: -> { respond_to?(:review_status) }
    validate :records_belong_to_organization
  end

  def confirmed?
    review_status == "confirmed"
  end

  private

    def records_belong_to_organization
      linked_records_for_tenant_check.compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end

    def linked_records_for_tenant_check
      [ master_agreement ]
    end
end
