class MasterAgreementDeliveryLocation < ApplicationRecord
  include MasterAgreementExtractionRecord

  belongs_to :master_agreement_schedule

  validates :name, presence: true

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_schedule ]
    end
end
