class MasterAgreementProductPriceLine < ApplicationRecord
  include MasterAgreementExtractionRecord

  belongs_to :master_agreement_schedule

  validates :participating_company, :product_description, presence: true
  validates :case_pack, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :size, :unit_cost_delivered, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_schedule ]
    end
end
