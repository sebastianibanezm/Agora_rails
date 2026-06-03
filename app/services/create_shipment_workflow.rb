class CreateShipmentWorkflow
  def self.call(shipment)
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
          BuildShipmentDocumentDependencies.call(shipment)
          shipment.shipment_documents.find_each { |document| RecalculateShipmentDocumentStatus.call(document) }
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
      find_or_create!(organization.shipment_documents,
                      shipment: shipment,
                      document_template: template,
                      documentable: documentable) do |document|
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
      end
    end
end
