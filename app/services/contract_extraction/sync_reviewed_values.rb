module ContractExtraction
  class SyncReviewedValues
    AGREEMENT_FIELD_KEYS = %w[
      customer_legal_name
      vendor_legal_name
      contract_effective_date
      contract_expiration_date
      schedule_effective_date
      schedule_expiration_date
      payment_terms
      delivery_terms
      lead_time_days
      first_delivery_date
      service_level_commitment
      recall_contacts
      compliance_requirements
      delivery_locations
      specifications_reference
      pallet_requirements
      unsaleables_terms
    ].freeze

    def self.call(master_agreement)
      ServiceResult.capture { call!(master_agreement) }
    end

    def self.call!(master_agreement)
      new(master_agreement).call
    end

    def initialize(master_agreement)
      @master_agreement = master_agreement
      @organization = master_agreement.organization
    end

    def call
      ActsAsTenant.with_tenant(organization) do
        MasterAgreement.transaction do
          update_agreement_columns
          sync_agreement_document_fields
        end
      end
    end

    private

      attr_reader :master_agreement, :organization

      def update_agreement_columns
        schedule = confirmed_schedules.first
        attrs = {}
        attrs[:effective_on] = confirmed_date("contract_effective_date") || schedule&.effective_on if master_agreement.effective_on.blank?
        attrs[:expires_on] = confirmed_date("contract_expiration_date") || schedule&.expires_on if master_agreement.expires_on.blank?
        attrs[:payment_terms] = confirmed_raw("payment_terms") || schedule&.payment_terms if master_agreement.payment_terms.blank?
        attrs[:currency] = schedule&.currency if master_agreement.currency.blank? && schedule&.currency.present?
        master_agreement.update!(attrs.compact) if attrs.any?
      end

      def sync_agreement_document_fields
        field_payloads = agreement_field_payloads
        return if field_payloads.blank?

        master_agreement.shipment_documents.includes(document_template: :document_template_fields).find_each do |document|
          next unless document.agreement_level?

          document.document_template.document_template_fields.includes(:document_field_definition).find_each do |template_field|
            field = template_field.document_field_definition
            payload = field_payloads[field.key]
            next unless payload

            value = organization.shipment_document_field_values.find_or_initialize_by(
              shipment_document: document,
              document_field_definition: field
            )
            value.value = payload.fetch(:value)
            value.raw_value = payload.fetch(:raw_value)
            value.source = "imported"
            value.confirmed = true
            value.save!
          end
        end
      end

      def agreement_field_payloads
        AGREEMENT_FIELD_KEYS.to_h do |field_key|
          raw_value = value_for_field(field_key)
          [ field_key, raw_value.present? ? { raw_value: raw_value.to_s, value: raw_value } : nil ]
        end.compact
      end

      def value_for_field(field_key)
        confirmed_raw(field_key) || derived_value_for(field_key)
      end

      def derived_value_for(field_key)
        schedule = confirmed_schedules.first
        case field_key
        when "customer_legal_name"
          confirmed_party("customer")&.legal_name || confirmed_party("customer")&.name
        when "vendor_legal_name"
          confirmed_party("vendor")&.legal_name || confirmed_party("vendor")&.name
        when "contract_effective_date"
          master_agreement.effective_on&.iso8601
        when "contract_expiration_date"
          master_agreement.expires_on&.iso8601
        when "schedule_effective_date"
          schedule&.effective_on&.iso8601
        when "schedule_expiration_date"
          schedule&.expires_on&.iso8601
        when "payment_terms"
          schedule&.payment_terms
        when "delivery_terms"
          schedule&.delivery_terms
        when "lead_time_days"
          schedule&.lead_time_days
        when "first_delivery_date"
          schedule&.first_delivery_on&.iso8601
        when "delivery_locations"
          confirmed_locations.map { |location| [ location.code, location.name, location.city, location.state_region ].compact_blank.join(" ") }.join("; ")
        when "specifications_reference"
          schedule&.specifications_reference
        when "pallet_requirements"
          schedule&.pallet_requirements&.join(", ")
        when "unsaleables_terms"
          schedule&.unsaleables_terms
        when "recall_contacts"
          confirmed_contacts.select { |contact| contact.contact_type.in?(%w[emergency recall qa category_manager]) }
                            .map { |contact| [ contact.name, contact.title, contact.phone, contact.email ].compact_blank.join(" | ") }
                            .join("; ")
        when "compliance_requirements"
          master_agreement.master_agreement_clauses
                          .where(review_status: "confirmed")
                          .order(:section_number)
                          .map { |clause| [ clause.section_number, clause.title, clause.summary ].compact_blank.join(" - ") }
                          .join("; ")
        end
      end

      def confirmed_raw(field_key)
        confirmed_values[field_key]&.raw_value
      end

      def confirmed_date(field_key)
        value = confirmed_raw(field_key)
        return if value.blank?

        Date.parse(value)
      rescue ArgumentError
        nil
      end

      def confirmed_values
        @confirmed_values ||= master_agreement.master_agreement_extracted_values
                                      .where(review_status: "confirmed")
                                      .order(updated_at: :asc)
                                      .to_a
                                      .index_by(&:field_key)
      end

      def confirmed_party(role)
        master_agreement.master_agreement_parties.where(review_status: "confirmed", party_role: role).order(updated_at: :desc).first
      end

      def confirmed_contacts
        @confirmed_contacts ||= master_agreement.master_agreement_contacts.where(review_status: "confirmed").to_a
      end

      def confirmed_schedules
        @confirmed_schedules ||= master_agreement.master_agreement_schedules.where(review_status: "confirmed").order(effective_on: :desc, updated_at: :desc).to_a
      end

      def confirmed_locations
        @confirmed_locations ||= master_agreement.master_agreement_delivery_locations.where(review_status: "confirmed").to_a
      end
  end
end
