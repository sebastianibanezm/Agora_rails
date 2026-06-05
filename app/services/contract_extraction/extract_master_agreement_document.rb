module ContractExtraction
  class ExtractMasterAgreementDocument
    def self.call(master_agreement_document, client: AiClient.new)
      ServiceResult.capture { new(master_agreement_document, client: client).call }
    end

    def self.call!(master_agreement_document, client: AiClient.new)
      new(master_agreement_document, client: client).call
    end

    def initialize(master_agreement_document, client:)
      @master_agreement_document = master_agreement_document
      @master_agreement = master_agreement_document.master_agreement
      @organization = master_agreement_document.organization
      @client = client
    end

    def call
      ActsAsTenant.with_tenant(organization) do
        raise "Attach a PDF before extraction" unless master_agreement_document.file.attached?

        master_agreement_document.update!(extraction_status: "processing", extraction_error: nil)
        pdf_content = PdfContent.call(master_agreement_document)
        extraction = client.extract(master_agreement_document, pdf_content)

        MasterAgreementDocument.transaction do
          master_agreement_document.update!(
            extraction_status: "needs_review",
            extracted_text: pdf_content.fetch(:pages).map { |page| "Page #{page.number}\n#{page.text}" }.join("\n\n"),
            extracted_data: extraction
          )
          persist_extraction!(extraction)
        end
      end
    rescue StandardError => error
      master_agreement_document.update!(extraction_status: "failed", extraction_error: error.message) if master_agreement_document.persisted?
      raise
    end

    private

      attr_reader :master_agreement_document, :master_agreement, :organization, :client

      def persist_extraction!(extraction)
        clear_previous_extraction!
        update_document_metadata!(extraction.fetch("document", {}))
        persist_parties!(extraction.fetch("parties", []))
        persist_contacts!(extraction.fetch("contacts", []))
        persist_signers!(extraction.fetch("signers", []))
        persist_schedules!(extraction.fetch("schedules", []))
        persist_clauses!(extraction.fetch("clauses", []))
        persist_values!(extraction.fetch("extracted_values", []))
      end

      def clear_previous_extraction!
        master_agreement_document.master_agreement_extracted_values.destroy_all
        master_agreement_document.master_agreement_parties.destroy_all
        master_agreement_document.master_agreement_contacts.destroy_all
        master_agreement_document.master_agreement_signers.destroy_all
        master_agreement_document.master_agreement_schedules.destroy_all
        master_agreement_document.master_agreement_clauses.destroy_all
      end

      def update_document_metadata!(metadata)
        docusign = metadata.fetch("docusign", {})
        master_agreement_document.update!(
          title: metadata["title"].presence || master_agreement_document.title,
          document_kind: metadata["document_kind"].presence_in(MasterAgreementDocument::DOCUMENT_KINDS) || master_agreement_document.document_kind,
          effective_on: date_value(metadata["effective_on"]) || master_agreement_document.effective_on,
          expires_on: date_value(metadata["expires_on"]) || master_agreement_document.expires_on,
          docusign_envelope_id: docusign["envelope_id"],
          docusign_status: docusign["status"],
          docusign_subject: docusign["subject"],
          docusign_originator_name: docusign["originator_name"],
          docusign_originator_email: docusign["originator_email"],
          docusign_time_zone: docusign["time_zone"]
        )
      end

      def persist_parties!(parties)
        Array(parties).each do |party|
          next if party["name"].blank? && party["legal_name"].blank?

          organization.master_agreement_parties.create!(
            master_agreement: master_agreement,
            master_agreement_document: master_agreement_document,
            party_role: normalized_value(party["party_role"], MasterAgreementParty::PARTY_ROLES, "other"),
            name: party["name"].presence || party["legal_name"],
            legal_name: party["legal_name"],
            state_of_incorporation: party["state_of_incorporation"],
            source_page: party["source_page"],
            confidence: party["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def persist_contacts!(contacts)
        Array(contacts).each do |contact|
          next if [ contact["name"], contact["title"], contact["phone"], contact["email"], contact["address"] ].all?(&:blank?)

          organization.master_agreement_contacts.create!(
            master_agreement: master_agreement,
            master_agreement_document: master_agreement_document,
            contact_type: normalized_value(contact["contact_type"], MasterAgreementContact::CONTACT_TYPES, "other"),
            party_role: normalized_value(contact["party_role"], MasterAgreementContact::PARTY_ROLES, nil),
            name: contact["name"],
            title: contact["title"],
            phone: contact["phone"],
            email: contact["email"],
            address: contact["address"],
            source_page: contact["source_page"],
            confidence: contact["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def persist_signers!(signers)
        Array(signers).each do |signer|
          next if signer["name"].blank?

          organization.master_agreement_signers.create!(
            master_agreement: master_agreement,
            master_agreement_document: master_agreement_document,
            party_role: normalized_value(signer["party_role"], MasterAgreementParty::PARTY_ROLES, "other"),
            name: signer["name"],
            email: signer["email"],
            title: signer["title"],
            company: signer["company"],
            sent_at: time_value(signer["sent_at"]),
            viewed_at: time_value(signer["viewed_at"]),
            signed_at: time_value(signer["signed_at"]),
            disclosure_accepted_at: time_value(signer["disclosure_accepted_at"]),
            ip_address: signer["ip_address"],
            signature_method: signer["signature_method"],
            source_page: signer["source_page"],
            confidence: signer["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def persist_schedules!(schedules)
        Array(schedules).each do |schedule_attrs|
          schedule = organization.master_agreement_schedules.create!(
            master_agreement: master_agreement,
            master_agreement_document: master_agreement_document,
            schedule_number: schedule_attrs["schedule_number"],
            title: schedule_attrs["title"].presence || "Schedule",
            product_category: schedule_attrs["product_category"],
            currency: schedule_attrs["currency"],
            effective_on: date_value(schedule_attrs["effective_on"]),
            expires_on: date_value(schedule_attrs["expires_on"]),
            first_delivery_on: date_value(schedule_attrs["first_delivery_on"]),
            payment_terms: schedule_attrs["payment_terms"],
            lead_time_days: schedule_attrs["lead_time_days"],
            lead_time_description: schedule_attrs["lead_time_description"],
            delivery_terms: schedule_attrs["delivery_terms"],
            specifications_reference: schedule_attrs["specifications_reference"],
            incentives: schedule_attrs["incentives"],
            unsaleables_terms: schedule_attrs["unsaleables_terms"],
            pricing_adjustment_terms: schedule_attrs["pricing_adjustment_terms"],
            participating_companies: string_array(schedule_attrs["participating_companies"]),
            distributors: string_array(schedule_attrs["distributors"]),
            pallet_requirements: string_array(schedule_attrs["pallet_requirements"]),
            source_page: schedule_attrs["source_page"],
            confidence: schedule_attrs["confidence"],
            review_status: "pending_review"
          )

          persist_delivery_locations!(schedule, schedule_attrs["delivery_locations"])
          persist_product_price_lines!(schedule, schedule_attrs["product_pricing_lines"])
        end
      end

      def persist_delivery_locations!(schedule, locations)
        Array(locations).each do |location|
          next if location["name"].blank?

          organization.master_agreement_delivery_locations.create!(
            master_agreement: master_agreement,
            master_agreement_schedule: schedule,
            code: location["code"],
            name: location["name"],
            address: location["address"],
            city: location["city"],
            state_region: location["state_region"],
            postal_code: location["postal_code"],
            country: location["country"],
            source_page: location["source_page"],
            confidence: location["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def persist_product_price_lines!(schedule, price_lines)
        Array(price_lines).each do |line|
          next if line["participating_company"].blank? || line["product_description"].blank?

          organization.master_agreement_product_price_lines.create!(
            master_agreement: master_agreement,
            master_agreement_schedule: schedule,
            participating_company: line["participating_company"],
            product_description: line["product_description"],
            case_pack: line["case_pack"],
            size: line["size"],
            uom: line["uom"],
            unit_cost_delivered: line["unit_cost_delivered"],
            currency: line["currency"] || schedule.currency,
            source_page: line["source_page"],
            confidence: line["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def persist_clauses!(clauses)
        Array(clauses).each do |clause|
          next if clause["section_number"].blank? || clause["title"].blank?

          organization.master_agreement_clauses.create!(
            master_agreement: master_agreement,
            master_agreement_document: master_agreement_document,
            section_number: clause["section_number"],
            title: clause["title"],
            summary: clause["summary"],
            obligations: Array(clause["obligations"]),
            source_page: clause["source_page"],
            confidence: clause["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def persist_values!(values)
        Array(values).each do |value|
          next if value["field_key"].blank?

          organization.master_agreement_extracted_values.create!(
            master_agreement: master_agreement,
            master_agreement_document: master_agreement_document,
            field_key: value["field_key"],
            label: value["label"].presence || value["field_key"].to_s.humanize,
            raw_value: value["raw_value"],
            normalized_value: value["normalized_value"].presence || {},
            source_label: value["source_label"],
            page_number: value["page_number"],
            confidence: value["confidence"],
            review_status: "pending_review"
          )
        end
      end

      def normalized_value(value, allowed_values, fallback)
        value.presence_in(allowed_values) || fallback
      end

      def string_array(value)
        Array(value).map(&:presence).compact
      end

      def date_value(value)
        return value if value.is_a?(Date)
        return if value.blank?

        Date.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      def time_value(value)
        return value if value.is_a?(Time)
        return if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end
  end
end
