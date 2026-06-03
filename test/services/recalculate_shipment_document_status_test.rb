require "test_helper"

class RecalculateShipmentDocumentStatusTest < ActiveSupport::TestCase
  test "approving prerequisite unlocks dependent document" do
    shipment = create(:shipment)
    dependent = shipment.shipment_documents.joins(:document_template).find_by!(document_templates: { code: "shipping_instruction" })
    prerequisites = dependent.incoming_dependencies.includes(:prerequisite_shipment_document).map(&:prerequisite_shipment_document)
    prerequisite = prerequisites.first
    prerequisites.drop(1).each { |document| document.update!(status: "approved") }

    RecalculateShipmentDocumentStatus.call(dependent)
    assert_equal "blocked", dependent.reload.status

    prerequisite.update!(status: "approved")
    RecalculateShipmentDocumentStatus.call(prerequisite)

    assert_equal "pending", dependent.reload.status
  end

  test "cyclic runtime dependencies terminate without infinite recursion" do
    shipment = create(:shipment)
    first, second = shipment.shipment_documents.limit(2).to_a

    find_or_create_dependency(shipment, first, second)
    find_or_create_dependency(shipment, second, first)

    RecalculateShipmentDocumentStatus.call(first)

    assert first.reload.status.in?(ShipmentDocument::STATUSES)
    assert second.reload.status.in?(ShipmentDocument::STATUSES)
  end

  private

    def find_or_create_dependency(shipment, dependent, prerequisite)
      shipment.organization.shipment_document_dependencies.find_or_create_by!(
        shipment_document: dependent,
        prerequisite_shipment_document: prerequisite
      )
    end
end
