class MasterAgreementsController < ApplicationController
  before_action :set_master_agreement, only: :show

  def index
    authorize MasterAgreement

    agreement_scope = policy_scope(Current.organization.master_agreements)
    pagination = pagination_for(agreement_scope)
    agreements = agreement_scope
                   .includes(:trading_partner, :shipment_documents, purchase_orders: :shipments)
                   .order(created_at: :desc)
                   .limit(pagination[:per_page])
                   .offset((pagination[:page] - 1) * pagination[:per_page])

    render inertia: "MasterAgreements/Index", props: {
      org_slug: params[:org_slug],
      agreements: agreements.map { |agreement| agreement_payload(agreement) },
      pagination: pagination
    }
  end

  def show
    authorize @master_agreement
    preload_master_agreement_detail

    render inertia: "MasterAgreements/Show", props: {
      org_slug: params[:org_slug],
      agreement: agreement_payload(@master_agreement),
      purchase_orders: purchase_orders_payload,
      contract_documents: contract_documents_payload,
      contract_packet: contract_packet_payload
    }
  end

  private

    def set_master_agreement
      @master_agreement = Current.organization.master_agreements.find(params[:id])
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

    def preload_master_agreement_detail
      ActiveRecord::Associations::Preloader.new(
        records: [ @master_agreement ],
        associations: [
          :trading_partner,
          :master_agreement_extracted_values,
          :master_agreement_parties,
          :master_agreement_contacts,
          :master_agreement_signers,
          :master_agreement_clauses,
          {
            master_agreement_documents: [
              :file_attachment,
              :master_agreement_extracted_values,
              :master_agreement_parties,
              :master_agreement_contacts,
              :master_agreement_signers,
              :master_agreement_schedules,
              :master_agreement_clauses
            ]
          },
          {
            master_agreement_schedules: [
              :master_agreement_delivery_locations,
              :master_agreement_product_price_lines
            ]
          },
          {
            shipment_documents: [
              :document_template,
              { incoming_dependencies: { prerequisite_shipment_document: :document_template } },
              { shipment_document_field_values: :document_field_definition }
            ]
          },
          {
            purchase_orders: [
              :trading_partner,
              :purchase_order_lines,
              {
                shipments: {
                  shipment_documents: [
                    :document_template,
                    { incoming_dependencies: { prerequisite_shipment_document: :document_template } },
                    { shipment_document_field_values: :document_field_definition }
                  ]
                }
              }
            ]
          }
        ]
      ).call
    end

    def agreement_payload(agreement)
      purchase_orders = agreement.purchase_orders
      shipments = purchase_orders.flat_map(&:shipments)
      contract_documents = agreement.shipment_documents
      approved_contract_documents = contract_documents.count(&:approved_or_waived?)

      {
        id: agreement.id,
        agreement_number: agreement.agreement_number,
        name: agreement.name,
        status: agreement.status,
        effective_on: agreement.effective_on&.iso8601,
        expires_on: agreement.expires_on&.iso8601,
        incoterm: agreement.incoterm,
        payment_terms: agreement.payment_terms,
        currency: agreement.currency,
        total_amount: purchase_orders.sum { |purchase_order| purchase_order.total_amount.to_d },
        trading_partner: {
          id: agreement.trading_partner.id,
          name: agreement.trading_partner.name,
          legal_name: agreement.trading_partner.legal_name,
          country: agreement.trading_partner.country
        },
        counts: {
          purchase_orders: purchase_orders.size,
          shipments: shipments.size,
          contract_documents: contract_documents.size
        },
        contract_document_progress: {
          approved: approved_contract_documents,
          total: contract_documents.size
        },
        extraction_summary: {
          documents: agreement.master_agreement_documents.size,
          pending_review: agreement.master_agreement_documents.count { |document| document.extraction_status == "needs_review" },
          confirmed_values: agreement.master_agreement_extracted_values.count { |value| value.review_status == "confirmed" }
        }
      }
    end

    def contract_packet_payload
      {
        documents: @master_agreement.master_agreement_documents.sort_by(&:created_at).map { |document| contract_packet_document_payload(document) },
        extracted_values: @master_agreement.master_agreement_extracted_values.sort_by { |value| [ value.review_status, value.field_key ] }.map { |value| extracted_value_payload(value) },
        parties: @master_agreement.master_agreement_parties.sort_by { |party| [ party.party_role, party.name ] }.map { |party| party_payload(party) },
        contacts: @master_agreement.master_agreement_contacts.sort_by { |contact| [ contact.contact_type, contact.name.to_s ] }.map { |contact| contact_payload(contact) },
        signers: @master_agreement.master_agreement_signers.sort_by { |signer| [ signer.signed_at || Time.zone.at(0), signer.name ] }.map { |signer| signer_payload(signer) },
        schedules: @master_agreement.master_agreement_schedules.sort_by { |schedule| [ schedule.effective_on || Date.new(9999, 12, 31), schedule.title ] }.map { |schedule| schedule_payload(schedule) },
        clauses: @master_agreement.master_agreement_clauses.sort_by { |clause| [ clause.section_number.to_s, clause.title ] }.map { |clause| clause_payload(clause) }
      }
    end

    def contract_packet_document_payload(document)
      {
        id: document.id,
        title: document.title,
        document_kind: document.document_kind,
        effective_on: document.effective_on&.iso8601,
        expires_on: document.expires_on&.iso8601,
        extraction_status: document.extraction_status,
        extraction_error: document.extraction_error,
        reviewed_at: document.reviewed_at&.iso8601,
        file_name: document.file.attached? ? document.file.filename.to_s : nil,
        docusign: {
          envelope_id: document.docusign_envelope_id,
          status: document.docusign_status,
          subject: document.docusign_subject,
          originator_name: document.docusign_originator_name,
          originator_email: document.docusign_originator_email,
          time_zone: document.docusign_time_zone
        },
        counts: {
          extracted_values: document.master_agreement_extracted_values.size,
          schedules: document.master_agreement_schedules.size,
          clauses: document.master_agreement_clauses.size
        }
      }
    end

    def extracted_value_payload(value)
      {
        id: value.id,
        document_id: value.master_agreement_document_id,
        field_key: value.field_key,
        label: value.label,
        raw_value: value.raw_value,
        normalized_value: value.normalized_value,
        source_label: value.source_label,
        page_number: value.page_number,
        confidence: value.confidence&.to_f,
        review_status: value.review_status
      }
    end

    def party_payload(party)
      {
        id: party.id,
        document_id: party.master_agreement_document_id,
        party_role: party.party_role,
        name: party.name,
        legal_name: party.legal_name,
        state_of_incorporation: party.state_of_incorporation,
        source_page: party.source_page,
        confidence: party.confidence&.to_f,
        review_status: party.review_status
      }
    end

    def contact_payload(contact)
      {
        id: contact.id,
        document_id: contact.master_agreement_document_id,
        contact_type: contact.contact_type,
        party_role: contact.party_role,
        name: contact.name,
        title: contact.title,
        phone: contact.phone,
        email: contact.email,
        address: contact.address,
        source_page: contact.source_page,
        confidence: contact.confidence&.to_f,
        review_status: contact.review_status
      }
    end

    def signer_payload(signer)
      {
        id: signer.id,
        document_id: signer.master_agreement_document_id,
        party_role: signer.party_role,
        name: signer.name,
        email: signer.email,
        title: signer.title,
        company: signer.company,
        sent_at: signer.sent_at&.iso8601,
        viewed_at: signer.viewed_at&.iso8601,
        signed_at: signer.signed_at&.iso8601,
        disclosure_accepted_at: signer.disclosure_accepted_at&.iso8601,
        ip_address: signer.ip_address,
        signature_method: signer.signature_method,
        source_page: signer.source_page,
        confidence: signer.confidence&.to_f,
        review_status: signer.review_status
      }
    end

    def schedule_payload(schedule)
      {
        id: schedule.id,
        document_id: schedule.master_agreement_document_id,
        title: schedule.title,
        schedule_number: schedule.schedule_number,
        product_category: schedule.product_category,
        currency: schedule.currency,
        effective_on: schedule.effective_on&.iso8601,
        expires_on: schedule.expires_on&.iso8601,
        first_delivery_on: schedule.first_delivery_on&.iso8601,
        payment_terms: schedule.payment_terms,
        lead_time_days: schedule.lead_time_days,
        lead_time_description: schedule.lead_time_description,
        delivery_terms: schedule.delivery_terms,
        specifications_reference: schedule.specifications_reference,
        incentives: schedule.incentives,
        unsaleables_terms: schedule.unsaleables_terms,
        pricing_adjustment_terms: schedule.pricing_adjustment_terms,
        participating_companies: schedule.participating_companies,
        distributors: schedule.distributors,
        pallet_requirements: schedule.pallet_requirements,
        source_page: schedule.source_page,
        confidence: schedule.confidence&.to_f,
        review_status: schedule.review_status,
        delivery_locations: schedule.master_agreement_delivery_locations.sort_by(&:name).map { |location| delivery_location_payload(location) },
        product_price_lines: schedule.master_agreement_product_price_lines.sort_by { |line| [ line.participating_company, line.product_description ] }.map { |line| product_price_line_payload(line) }
      }
    end

    def delivery_location_payload(location)
      {
        id: location.id,
        code: location.code,
        name: location.name,
        address: location.address,
        city: location.city,
        state_region: location.state_region,
        postal_code: location.postal_code,
        country: location.country,
        source_page: location.source_page,
        confidence: location.confidence&.to_f,
        review_status: location.review_status
      }
    end

    def product_price_line_payload(line)
      {
        id: line.id,
        participating_company: line.participating_company,
        product_description: line.product_description,
        case_pack: line.case_pack,
        size: line.size&.to_s,
        uom: line.uom,
        unit_cost_delivered: line.unit_cost_delivered&.to_s,
        currency: line.currency,
        source_page: line.source_page,
        confidence: line.confidence&.to_f,
        review_status: line.review_status
      }
    end

    def clause_payload(clause)
      {
        id: clause.id,
        document_id: clause.master_agreement_document_id,
        section_number: clause.section_number,
        title: clause.title,
        summary: clause.summary,
        obligations: clause.obligations,
        source_page: clause.source_page,
        confidence: clause.confidence&.to_f,
        review_status: clause.review_status
      }
    end

    def purchase_orders_payload
      @master_agreement.purchase_orders
                       .sort_by { |purchase_order| [ purchase_order.required_ship_on || Date.new(9999, 12, 31), purchase_order.po_number ] }
                       .map do |purchase_order|
        {
          id: purchase_order.id,
          po_number: purchase_order.po_number,
          status: purchase_order.status,
          issued_on: purchase_order.issued_on&.iso8601,
          required_ship_on: purchase_order.required_ship_on&.iso8601,
          destination_country: purchase_order.destination_country,
          incoterm: purchase_order.incoterm,
          total_amount: purchase_order.total_amount,
          currency: purchase_order.currency || @master_agreement.currency,
          lines_count: purchase_order.purchase_order_lines.size,
          items: purchase_order.purchase_order_lines.sort_by(&:sku).map do |line|
            item_documents = shipments_for_purchase_order(purchase_order).flat_map(&:workflow_documents).select do |document|
              document.documentable_type == "PurchaseOrderLine" && document.documentable_id == line.id
            end

            {
              id: line.id,
              sku: line.sku,
              label: line.product_description.presence || line.sku,
              quantity: line.quantity&.to_s,
              unit: line.unit,
              packaging: line.packaging,
              hs_code: line.hs_code,
              documents_count: item_documents.size,
              documents: item_documents.map { |document| document_payload(document) }
            }
          end,
          shipments: purchase_order.shipments.sort_by(&:created_at).map do |shipment|
            workflow_documents = shipment.workflow_documents.includes(
              :document_template,
              { incoming_dependencies: { prerequisite_shipment_document: :document_template } },
              { shipment_document_field_values: :document_field_definition }
            )
            documents_count = workflow_documents.size
            approved_count = workflow_documents.count(&:approved_or_waived?)

            {
              id: shipment.id,
              shipment_number: shipment.shipment_number,
              status: shipment.status,
              etd: shipment.etd&.to_date&.iso8601,
              destination_country: shipment.destination_country,
              pol: shipment.pol,
              pod: shipment.pod,
              booking_number: shipment.booking_number,
              document_progress: {
                approved: approved_count,
                total: documents_count
              },
              documents: workflow_documents.map { |document| document_payload(document) }
            }
          end
        }
      end
    end

    def contract_documents_payload
      @master_agreement.shipment_documents
                       .sort_by { |document| [ document.document_template.step_number || 999, document.document_template.name ] }
                       .map { |document| document_payload(document) }
    end

    def shipments_for_purchase_order(purchase_order)
      purchase_order.shipments.to_a
    end

    def document_payload(document)
      {
        id: document.id,
        name: document.document_template.name,
        code: document.document_template.code,
        status: document.status,
        obligation: document.document_template.obligation,
        criticality: document.document_template.criticality,
        grain: document.document_template.grain,
        assigned_role: document.assigned_role,
        documentable_type: document.documentable_type,
        deps: document.incoming_dependencies.map(&:prerequisite_shipment_document_id),
        blocked_by: document.incoming_dependencies.select { |dependency| dependency.status == "open" }.map do |dependency|
          {
            id: dependency.prerequisite_shipment_document_id,
            label: dependency.prerequisite_shipment_document.document_template.name,
            status: dependency.status
          }
        end,
        fields: document.shipment_document_field_values.map do |field_value|
          {
            id: field_value.id,
            name: field_value.document_field_definition.name,
            raw_value: field_value.raw_value,
            value: field_value.value,
            source: field_value.source,
            confirmed: field_value.confirmed
          }
        end
      }
    end
end
