class MasterAgreementSchedule < ApplicationRecord
  include MasterAgreementExtractionRecord

  belongs_to :master_agreement_document
  has_many :master_agreement_delivery_locations, dependent: :destroy
  has_many :master_agreement_product_price_lines, dependent: :destroy

  validates :title, presence: true
  validate :array_fields_are_string_arrays

  private

    def linked_records_for_tenant_check
      [ master_agreement, master_agreement_document ]
    end

    def array_fields_are_string_arrays
      %i[participating_companies distributors pallet_requirements].each do |attribute|
        values = public_send(attribute)
        next if values.is_a?(Array) && values.all? { |value| value.is_a?(String) && value.present? }

        errors.add(attribute, "must contain only non-empty strings")
      end
    end
end
