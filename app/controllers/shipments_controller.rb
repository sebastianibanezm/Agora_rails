class ShipmentsController < ApplicationController
  before_action :set_shipment, only: %i[show validate_source_of_truth]

  def index
    authorize Shipment

    shipment_scope = policy_scope(Current.organization.shipments)
    pagination = pagination_for(shipment_scope)
    shipments = shipment_scope
                  .includes({ shipment_documents: :document_template }, purchase_order: :trading_partner)
                  .order(created_at: :desc)
                  .limit(pagination[:per_page])
                  .offset((pagination[:page] - 1) * pagination[:per_page])

    render inertia: "Shipments/Index", props: {
      org_slug: params[:org_slug],
      shipments: shipments.map { |shipment| shipment_payload(shipment) },
      pagination: pagination
    }
  end

  def show
    authorize @shipment
    preload_shipment_detail

    render inertia: "Shipments/Show", props: {
      org_slug: params[:org_slug],
      shipment: shipment_payload(@shipment),
      graph: graph_payload,
      documents: documents_payload,
      source_of_truth_checks: checks_payload
    }
  end

  def validate_source_of_truth
    authorize @shipment, :validate_source_of_truth?

    result = ValidateShipmentSourceOfTruth.call(@shipment)
    if result.success?
      redirect_to shipment_path(org_slug: params[:org_slug], id: @shipment), notice: "Validaciones actualizadas."
    else
      redirect_to shipment_path(org_slug: params[:org_slug], id: @shipment), alert: result.error_message
    end
  end

  private

    def set_shipment
      @shipment = Current.organization.shipments.find(params[:id])
    end

    def pagination_for(scope)
      per_page = params.fetch(:per_page, 25).to_i.clamp(1, 100)
      total_count = scope.count
      total_pages = [ (total_count.to_f / per_page).ceil, 1 ].max
      page = params.fetch(:page, 1).to_i.clamp(1, total_pages)

      {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages,
        prev_page: page > 1 ? page - 1 : nil,
        next_page: page < total_pages ? page + 1 : nil
      }
    end

    def preload_shipment_detail
      ActiveRecord::Associations::Preloader.new(
        records: [ @shipment ],
        associations: [
          { purchase_order: :trading_partner },
          { purchase_order: [ :purchase_order_lines, :master_agreement ] },
          :shipment_lots,
          :shipment_containers,
          {
            shipment_documents: [
              :document_template,
              { shipment_document_field_values: :document_field_definition },
              { incoming_dependencies: { prerequisite_shipment_document: :document_template } }
            ]
          },
          {
            source_of_truth_checks: [
              :document_field_definition,
              { authoritative_shipment_document: :document_template },
              { target_shipment_document: :document_template }
            ]
          }
        ]
      ).call
    end

    def shipment_payload(shipment)
      shipment_documents = shipment.shipment_documents.to_a
      documents_count = shipment_documents.size
      approved_count = shipment_documents.count(&:approved_or_waived?)
      purchase_order = shipment.purchase_order

      {
        id: shipment.id,
        shipment_number: shipment.shipment_number,
        status: shipment.status,
        etd: shipment.etd&.to_date&.iso8601,
        destination_country: shipment.destination_country,
        pol: shipment.pol,
        pod: shipment.pod,
        booking_number: shipment.booking_number,
        purchase_order: {
          id: purchase_order.id,
          po_number: purchase_order.po_number,
          trading_partner_name: purchase_order.trading_partner.name
        },
        document_progress: {
          approved: approved_count,
          total: documents_count
        }
      }
    end

    def documents_payload
      @shipment.shipment_documents
               .sort_by { |document| [ document.document_template.step_number || 999, document.document_template.name ] }
               .map do |document|
        {
          id: document.id,
          name: document.document_template.name,
          code: document.document_template.code,
          status: document.status,
          obligation: document.document_template.obligation,
          criticality: document.document_template.criticality,
          grain: document.document_template.grain,
          assigned_role: document.assigned_role,
          fields: document.shipment_document_field_values.map do |field_value|
            {
              id: field_value.id,
              name: field_value.document_field_definition.name,
              key: field_value.document_field_definition.key,
              raw_value: field_value.raw_value,
              value: field_value.value,
              source: field_value.source,
              confirmed: field_value.confirmed
            }
          end,
          blocked_by: document.incoming_dependencies.select { |dependency| dependency.status == "open" }.map do |dependency|
            dependency.prerequisite_shipment_document.document_template.name
          end
        }
      end
    end

    def graph_payload
      documents = sorted_documents
      document_nodes = documents.map { |document| graph_document_payload(document) }
      external_sources = external_sources_for(document_nodes)
      documentable_counts = documents.group_by(&:documentable_type).transform_values(&:size)
      purchase_order = @shipment.purchase_order
      trading_partner = purchase_order.trading_partner
      master_agreement = purchase_order.master_agreement

      {
        root: {
          id: "shipment-#{@shipment.id}",
          label: @shipment.shipment_number,
          status: @shipment.status,
          buyer: trading_partner.name,
          po_number: purchase_order.po_number,
          route: [ @shipment.pol, @shipment.pod ].compact_blank.join(" -> "),
          etd: @shipment.etd&.to_date&.iso8601,
          destination_country: @shipment.destination_country,
          booking_number: @shipment.booking_number,
          vessel: @shipment.vessel,
          voyage: @shipment.voyage
        },
        categories: graph_categories(documentable_counts),
        purchase_order: {
          id: "po-#{purchase_order.id}",
          label: purchase_order.po_number,
          status: purchase_order.status,
          buyer: trading_partner.name,
          incoterm: purchase_order.incoterm || @shipment.incoterm || master_agreement.incoterm,
          currency: purchase_order.currency || master_agreement.currency,
          total_amount: purchase_order.total_amount,
          issued_on: purchase_order.issued_on&.iso8601,
          required_ship_on: purchase_order.required_ship_on&.iso8601,
          destination_country: purchase_order.destination_country || @shipment.destination_country,
          consignee_name: purchase_order.consignee_name,
          documents_count: documentable_counts["PurchaseOrder"].to_i
        },
        items: purchase_order.purchase_order_lines.map do |line|
          {
            id: "item-#{line.id}",
            label: line.product_description.presence || line.sku,
            sku: line.sku,
            quantity: line.quantity&.to_s,
            unit: line.unit,
            packaging: line.packaging,
            hs_code: line.hs_code,
            documents_count: documents.count { |document| document.documentable_type == "PurchaseOrderLine" && document.documentable_id == line.id }
          }
        end,
        customer: {
          id: "customer-#{trading_partner.id}",
          label: trading_partner.name,
          legal_name: trading_partner.legal_name,
          country: trading_partner.country,
          partner_type: trading_partner.partner_type,
          tax_identifier: trading_partner.tax_identifier,
          email: trading_partner.email,
          phone: trading_partner.phone,
          master_agreement: master_agreement.name,
          agreement_number: master_agreement.agreement_number,
          payment_terms: master_agreement.payment_terms,
          documents_count: documentable_counts["MasterAgreement"].to_i
        },
        market: {
          id: "market-#{(@shipment.destination_country || purchase_order.destination_country || 'global').parameterize}",
          label: @shipment.destination_country || purchase_order.destination_country || "Mercado destino",
          region: @shipment.destination_country || purchase_order.destination_country || "Destino por confirmar",
          authority: "Reglas documentarias y fuente de verdad",
          documents_count: documents.count { |document| document.document_template.document_type == "regulatorio" || document.document_template.grain.in?(%w[embarque contenedor set_documentario]) }
        },
        documents: document_nodes,
        dependencies: graph_dependencies(documents),
        external_sources: external_sources,
        source_of_truth_checks: checks_payload
      }
    end

    def graph_categories(documentable_counts)
      [
        { id: "purchase_order", label: "Orden de compra", icon: "po", blurb: "PO, ruta y embarque", count: 1, enabled: true },
        { id: "items", label: "Items", icon: "apple", blurb: "SKU y lineas compradas", count: @shipment.purchase_order.purchase_order_lines.size, enabled: @shipment.purchase_order.purchase_order_lines.any? },
        { id: "customer", label: "Cliente", icon: "user", blurb: "Acuerdo y contraparte", count: 1, enabled: true },
        { id: "market", label: "Mercado", icon: "globe", blurb: "Destino y regulacion", count: documentable_counts["Shipment"].to_i, enabled: true }
      ]
    end

    def sorted_documents
      @shipment.shipment_documents
               .sort_by { |document| [ document.document_template.step_number || 999, document.documentable_type, document.document_template.name ] }
    end

    def graph_dependencies(documents)
      document_ids = documents.index_by(&:id)

      documents.flat_map do |document|
        document.incoming_dependencies.filter_map do |dependency|
          next unless document_ids.key?(dependency.prerequisite_shipment_document_id)

          {
            id: "dep-#{dependency.prerequisite_shipment_document_id}-#{document.id}",
            from: "doc-#{dependency.prerequisite_shipment_document_id}",
            to: "doc-#{document.id}",
            status: dependency.status
          }
        end
      end
    end

    def graph_document_payload(document)
      template = document.document_template
      field_sources = document.shipment_document_field_values.map(&:source).compact_blank.uniq
      external_key = external_source_key(template, field_sources)

      {
        id: document.id,
        graph_id: "doc-#{document.id}",
        label: template.name,
        short: template.code.to_s.upcase.truncate(12, omission: ""),
        type: icon_type_for(template),
        status: document.status,
        severity: severity_for(template.criticality, document.status),
        obligation: template.obligation,
        criticality: template.criticality,
        grain: template.grain,
        assigned_role: document.assigned_role,
        documentable_type: document.documentable_type,
        documentable_id: document.documentable_id,
        scope: scope_for(document),
        deps: document.incoming_dependencies.map { |dependency| "doc-#{dependency.prerequisite_shipment_document_id}" },
        ext: external_key,
        issued_by: external_key ? external_label(template, field_sources) : document.assigned_role,
        due_on: document.due_on&.iso8601,
        completed_at: document.completed_at&.iso8601,
        fields: document.shipment_document_field_values.map do |field_value|
          {
            id: field_value.id,
            name: field_value.document_field_definition.name,
            key: field_value.document_field_definition.key,
            raw_value: field_value.raw_value,
            value: field_value.value,
            source: field_value.source,
            confirmed: field_value.confirmed
          }
        end,
        blocked_by: document.incoming_dependencies.select { |dependency| dependency.status == "open" }.map do |dependency|
          {
            id: dependency.prerequisite_shipment_document_id,
            graph_id: "doc-#{dependency.prerequisite_shipment_document_id}",
            label: dependency.prerequisite_shipment_document.document_template.name
          }
        end
      }
    end

    # Temporary graph adapter: external providers are not first-class records yet,
    # so the workspace derives stable provider nodes from template generator roles
    # and non-manual field sources.
    def external_sources_for(document_nodes)
      document_nodes.filter_map { |document| document[:ext] }.uniq.map do |key|
        docs = document_nodes.select { |document| document[:ext] == key }
        label = docs.first[:issued_by].presence || key.to_s.titleize
        {
          id: key,
          name: label,
          code: label.split(/\s+/).first.to_s.upcase.truncate(8, omission: ""),
          kind: "Proveedor documental derivado",
          sla: "Segun workflow",
          documents_count: docs.size
        }
      end
    end

    def external_source_key(template, field_sources)
      label = external_label(template, field_sources)
      return if label.blank?

      label.parameterize.presence
    end

    def external_label(template, field_sources)
      generator = template.generator_roles.find { |role| role.present? && !role.match?(/agora|operaciones|comercial|finanzas|packing/i) }
      source = field_sources.find { |field_source| field_source.present? && field_source != "manual" }

      return generator if generator.present?
      return source.to_s.titleize if source.present?
      return template.generator_roles.first if template.document_type.in?(%w[externo regulatorio]) && template.generator_roles.first.present?

      nil
    end

    def scope_for(document)
      case document.documentable_type
      when "PurchaseOrder" then "purchase_order"
      when "PurchaseOrderLine" then "items"
      when "MasterAgreement" then "customer"
      else "market"
      end
    end

    def severity_for(criticality, status)
      return "ok" if status.in?(%w[approved waived])
      return "crit" if status.in?(%w[blocked rejected]) || criticality == "critico"
      return "watch" if criticality.in?(%w[alto medio])

      "info"
    end

    def icon_type_for(template)
      code = template.code.to_s
      return "invoice" if code.include?("invoice") || code.include?("factura")
      return "packing" if code.include?("packing") || code.include?("lista")
      return "bl" if code.include?("bl") || code.include?("bill")
      return "phyto" if code.include?("fito") || code.include?("phyto")
      return "inspection" if code.include?("insp")
      return "origin" if code.include?("origin")
      return "insurance" if code.include?("seguro") || code.include?("insur")
      return "customs" if code.include?("aduana") || code.include?("custom")
      return "testlab" if code.include?("lab")
      return "permit" if template.document_type == "regulatorio"

      "invoice"
    end

    def checks_payload
      @shipment.source_of_truth_checks
               .includes(:document_field_definition,
                         authoritative_shipment_document: :document_template,
                         target_shipment_document: :document_template)
               .order(updated_at: :desc)
               .map do |check|
        {
          id: check.id,
          status: check.status,
          field_name: check.document_field_definition.name,
          expected_value: check.expected_value,
          actual_value: check.actual_value,
          failure_action: check.failure_action,
          authoritative_document: check.authoritative_shipment_document.document_template.name,
          target_document: check.target_shipment_document.document_template.name
        }
      end
    end
end
