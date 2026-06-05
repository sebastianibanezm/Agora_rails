require "set"

class RecalculateShipmentDocumentStatus
  TERMINAL_DOCUMENT_STATUSES = %w[approved waived rejected].freeze
  TERMINAL_SHIPMENT_STATUSES = %w[shipped post_zarpe closed cancelled].freeze

  def self.call(shipment_document, visited: Set.new)
    ServiceResult.capture { call!(shipment_document, visited: visited) }
  end

  def self.call!(shipment_document, visited: Set.new)
    new(shipment_document, visited: visited).call
  end

  def initialize(shipment_document, visited:)
    @shipment_document = shipment_document
    @shipment = shipment_document.shipment
    @visited = visited
  end

  def call
    return if visited.include?(shipment_document.id)

    visited.add(shipment_document.id)

    ActsAsTenant.with_tenant(shipment_document.organization) do
      refresh_dependency_edges
      refresh_document_status
      refresh_dependent_documents
      refresh_shipment_status
    end
  end

  private

    attr_reader :shipment_document, :shipment, :visited

    def refresh_dependency_edges
      shipment_document.incoming_dependencies.includes(:prerequisite_shipment_document).find_each do |dependency|
        next if dependency.status == "waived"

        dependency.update!(status: dependency.prerequisite_shipment_document.approved_or_waived? ? "satisfied" : "open")
      end
    end

    def refresh_document_status
      return if shipment_document.status.in?(TERMINAL_DOCUMENT_STATUSES)

      next_status = shipment_document.incoming_dependencies.where(status: "open").exists? ? "blocked" : unblocked_status
      shipment_document.update!(status: next_status) if shipment_document.status != next_status
    end

    def refresh_dependent_documents
      shipment_document.outgoing_dependencies.includes(:shipment_document).find_each do |dependency|
        dependent = dependency.shipment_document
        next if dependent.status.in?(TERMINAL_DOCUMENT_STATUSES)

        RecalculateShipmentDocumentStatus.call!(dependent, visited: visited)
      end
    end

    def refresh_shipment_status
      return if shipment.status.in?(TERMINAL_SHIPMENT_STATUSES)

      required_documents = shipment.workflow_documents.joins(:document_template).where(document_templates: { obligation: "obligatorio" })
      next_status = required_documents.exists? && required_documents.all?(&:approved_or_waived?) ? "ready_to_ship" : "documents_pending"
      shipment.update_columns(status: next_status, updated_at: Time.current) if shipment.status != next_status
    end

    def unblocked_status
      shipment_document.status == "not_started" || shipment_document.status == "blocked" ? "pending" : shipment_document.status
    end
end
