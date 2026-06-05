class CreateShipmentWorkflow
  def self.call(shipment)
    ServiceResult.capture { call!(shipment) }
  end

  def self.call!(shipment)
    new(shipment).call
  end

  def initialize(shipment)
    @shipment = shipment
    @organization = shipment.organization
  end

  def call
    ActsAsTenant.with_tenant(organization) do
      Shipment.transaction do
        shipment.with_lock do
          create_documents
          BuildShipmentDocumentDependencies.call!(shipment)
          shipment.workflow_documents.find_each { |document| RecalculateShipmentDocumentStatus.call!(document) }
        end
      end
    end
  end

  private

    attr_reader :shipment, :organization

    def create_documents
      organization.document_templates.find_each do |template|
        next unless template.active?
        next unless template_applies?(template)

        documentables_for(template).compact.each do |documentable|
          document = create_document(template, documentable)
          create_field_values(document)
        end
      end
    end

    def create_document(template, documentable)
      return create_agreement_document(template, documentable) if documentable.is_a?(MasterAgreement)

      find_or_create!(organization.shipment_documents,
                      shipment: shipment,
                      document_template: template,
                      documentable: documentable) do |document|
        document.status = "pending"
        document.assigned_role = template.generator_roles.first
      end
    end

    def create_agreement_document(template, documentable)
      find_or_create!(organization.shipment_documents,
                      document_template: template,
                      documentable: documentable) do |document|
        document.shipment = shipment
        document.status = "pending"
        document.assigned_role = template.generator_roles.first
      end
    end

    def template_applies?(template)
      destination_applies?(template) && insurance_applies?(template)
    end

    def destination_applies?(template)
      template.destinations.blank? || template.destinations.include?(shipment.destination_country)
    end

    def insurance_applies?(template)
      return true unless template.code == "marine_insurance"

      shipment.incoterm.to_s.casecmp("CIF").zero?
    end

    def documentables_for(template)
      case template.grain
      when "relacion_comercial"
        [ shipment.master_agreement ]
      when "po"
        [ shipment.purchase_order ]
      when "sku_producto"
        organization.purchase_order_lines.where(purchase_order: shipment.purchase_order).to_a
      when "lote"
        organization.shipment_lots.where(shipment: shipment).to_a
      when "contenedor"
        organization.shipment_containers.where(shipment: shipment).to_a
      when "embarque", "set_documentario"
        [ shipment ]
      else
        []
      end
    end

    def create_field_values(document)
      document.document_template.document_template_fields.includes(:document_field_definition).find_each do |template_field|
        field = template_field.document_field_definition
        find_or_create!(organization.shipment_document_field_values,
                        shipment_document: document,
                        document_field_definition: field) do |value|
          prefill = prefilled_value_for(field.key, document.documentable)
          value.value = prefill
          value.raw_value = prefill.to_s if prefill.present?
          value.source = prefill.nil? ? "manual" : "derived"
          value.confirmed = false
        end
      end
    end

    def find_or_create!(relation, attributes)
      relation.find_by(attributes) || relation.create!(attributes) do |record|
        yield record if block_given?
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
      relation.find_by(attributes) || raise(error)
    end

    def prefilled_value_for(field_key, documentable)
      case field_key
      when "shipper_name"
        organization.name
      when "consignee"
        shipment.purchase_order.consignee_name
      when "notify_party"
        shipment.purchase_order.notify_party_name
      when "incoterm"
        shipment.incoterm.presence || shipment.purchase_order.incoterm || shipment.master_agreement&.incoterm
      when "invoice_amount"
        shipment.purchase_order.total_amount
      when "pol"
        shipment.pol
      when "pod"
        shipment.pod
      when "container_number"
        documentable.container_number if documentable.respond_to?(:container_number)
      when "seal_number"
        documentable.seal_number if documentable.respond_to?(:seal_number)
      when "gross_weight"
        documentable.gross_weight if documentable.respond_to?(:gross_weight)
      when "net_weight"
        documentable.net_weight if documentable.respond_to?(:net_weight)
      when "package_count"
        documentable.package_count if documentable.respond_to?(:package_count)
      when "lot_number"
        documentable.lot_number if documentable.respond_to?(:lot_number)
      when "hs_code"
        documentable.hs_code if documentable.respond_to?(:hs_code)
      when "product_description"
        documentable.product_description if documentable.respond_to?(:product_description)
      when "customer_legal_name"
        shipment.master_agreement&.trading_partner&.legal_name || shipment.master_agreement&.trading_partner&.name
      when "vendor_legal_name"
        confirmed_party_value("vendor")
      when "contract_effective_date"
        shipment.master_agreement&.effective_on
      when "contract_expiration_date"
        shipment.master_agreement&.expires_on
      when "schedule_effective_date"
        confirmed_schedule&.effective_on
      when "schedule_expiration_date"
        confirmed_schedule&.expires_on
      when "payment_terms"
        shipment.master_agreement&.payment_terms || confirmed_schedule&.payment_terms
      when "delivery_terms"
        confirmed_schedule&.delivery_terms
      when "lead_time_days"
        confirmed_schedule&.lead_time_days
      when "first_delivery_date"
        confirmed_schedule&.first_delivery_on
      when "service_level_commitment"
        confirmed_extracted_value("service_level_commitment")
      when "recall_contacts"
        confirmed_contacts_value
      when "compliance_requirements"
        confirmed_clauses_value
      when "unit_price"
        documentable.unit_price if documentable.respond_to?(:unit_price)
      when "case_pack"
        confirmed_price_line_for(documentable)&.case_pack
      when "uom"
        documentable.unit if documentable.respond_to?(:unit)
      when "delivery_locations"
        confirmed_locations_value
      when "specifications_reference"
        confirmed_schedule&.specifications_reference
      when "pallet_requirements"
        confirmed_schedule&.pallet_requirements&.join(", ")
      when "unsaleables_terms"
        confirmed_schedule&.unsaleables_terms
      end
    end

    def confirmed_schedule
      @confirmed_schedule ||= shipment.master_agreement&.master_agreement_schedules&.where(review_status: "confirmed")&.order(effective_on: :desc, updated_at: :desc)&.first
    end

    def confirmed_extracted_value(field_key)
      shipment.master_agreement&.master_agreement_extracted_values&.where(review_status: "confirmed", field_key: field_key)&.order(updated_at: :desc)&.first&.raw_value
    end

    def confirmed_party_value(role)
      party = shipment.master_agreement&.master_agreement_parties&.where(review_status: "confirmed", party_role: role)&.order(updated_at: :desc)&.first
      party&.legal_name || party&.name
    end

    def confirmed_contacts_value
      shipment.master_agreement&.master_agreement_contacts&.where(review_status: "confirmed")&.map do |contact|
        [ contact.name, contact.title, contact.phone, contact.email ].compact_blank.join(" | ")
      end&.join("; ")
    end

    def confirmed_clauses_value
      shipment.master_agreement&.master_agreement_clauses&.where(review_status: "confirmed")&.order(:section_number)&.map do |clause|
        [ clause.section_number, clause.title, clause.summary ].compact_blank.join(" - ")
      end&.join("; ")
    end

    def confirmed_locations_value
      shipment.master_agreement&.master_agreement_delivery_locations&.where(review_status: "confirmed")&.map do |location|
        [ location.code, location.name, location.city, location.state_region ].compact_blank.join(" ")
      end&.join("; ")
    end

    def confirmed_price_line_for(documentable)
      return unless documentable.respond_to?(:product_description)

      description = documentable.product_description.to_s
      shipment.master_agreement&.master_agreement_product_price_lines&.where(review_status: "confirmed")&.detect do |line|
        description.present? && line.product_description.to_s.casecmp(description).zero?
      end
    end
end
