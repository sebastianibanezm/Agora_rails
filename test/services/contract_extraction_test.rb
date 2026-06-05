require "test_helper"

class ContractExtractionTest < ActiveSupport::TestCase
  class StubClient
    def extract(_document, _pdf_content)
      {
        "document" => {
          "title" => "ADUSA Frozen Fruit Schedule",
          "document_kind" => "schedule",
          "effective_on" => "2025-02-01",
          "expires_on" => "2028-01-31",
          "docusign" => {
            "envelope_id" => "17119CE0",
            "status" => "Completed"
          }
        },
        "parties" => [
          { "party_role" => "customer", "name" => "Ahold Delhaize USA Services, LLC", "confidence" => 0.98 },
          { "party_role" => "vendor", "name" => "Comfrut International Inc.", "state_of_incorporation" => "FL", "confidence" => 0.98 }
        ],
        "contacts" => [
          { "contact_type" => "emergency", "party_role" => "vendor", "name" => "Enrique Lopez", "title" => "North American Sales Manager", "phone" => "727-318-2473", "email" => "enrique.lopez@comfrut.com" }
        ],
        "signers" => [
          { "party_role" => "vendor", "name" => "Enrique Lopez", "email" => "enrique.lopez@comfrut.com", "title" => "US General Manager", "signed_at" => "2024-10-22T17:02:47-08:00" }
        ],
        "schedules" => [
          {
            "title" => "Frozen Fruit",
            "product_category" => "FROZEN FRUIT/Frozen",
            "effective_on" => "2025-02-01",
            "expires_on" => "2028-01-31",
            "first_delivery_on" => "2025-02-05",
            "payment_terms" => "2% 15 Net 30 Days",
            "lead_time_days" => 15,
            "participating_companies" => [ "ADUSA Distribution, LLC", "The GIANT Company LLC" ],
            "distributors" => [ "C&S Wholesale Grocers, Inc." ],
            "pallet_requirements" => [ "Grade A Hardwood" ],
            "delivery_locations" => [
              { "code" => "74_Aberdeen", "name" => "Frozen Food Facility", "address" => "1000 Old Philadelphia Rd", "city" => "Aberdeen", "state_region" => "MD", "postal_code" => "21001" }
            ],
            "product_pricing_lines" => [
              { "participating_company" => "GIANT", "product_description" => "NP ORG BERRY MEDLY 10Z", "case_pack" => 8, "size" => 10, "uom" => "Ounce", "unit_cost_delivered" => 1.76, "currency" => "USD", "source_page" => 5, "confidence" => 0.87 }
            ]
          }
        ],
        "clauses" => [
          { "section_number" => "9", "title" => "Service Level Commitment", "summary" => "Vendor must maintain 95% service level." }
        ],
        "extracted_values" => [
          { "field_key" => "payment_terms", "label" => "Payment Terms", "raw_value" => "2% 15 Net 30 Days", "page_number" => 2, "confidence" => 0.96 }
        ]
      }
    end
  end

  test "extracts and persists normalized packet records for review" do
    org = create(:organization)
    agreement = create(:master_agreement, organization: org, payment_terms: nil)
    document = create(:master_agreement_document, organization: org, master_agreement: agreement)
    document.file.attach(io: StringIO.new("%PDF-1.4\n"), filename: "schedule.pdf", content_type: "application/pdf")

    ContractExtraction::ExtractMasterAgreementDocument.call!(document, client: StubClient.new)

    assert_equal "needs_review", document.reload.extraction_status
    assert_equal "schedule", document.document_kind
    assert_equal "17119CE0", document.docusign_envelope_id
    assert_equal 2, agreement.master_agreement_parties.count
    assert_equal 1, agreement.master_agreement_contacts.count
    assert_equal 1, agreement.master_agreement_signers.count
    assert_equal 1, agreement.master_agreement_schedules.count
    assert_equal 1, agreement.master_agreement_delivery_locations.count
    assert_equal 1, agreement.master_agreement_product_price_lines.count
    assert_equal 1, agreement.master_agreement_clauses.count
    assert_equal "pending_review", agreement.master_agreement_extracted_values.first.review_status
  end

  test "confirmed values sync to master agreement and agreement-level document fields" do
    org = create(:organization)
    agreement = create(:master_agreement, organization: org, payment_terms: nil)
    shipment = create(:shipment, purchase_order: create(:purchase_order, organization: org, trading_partner: agreement.trading_partner, master_agreement: agreement))
    CreateShipmentWorkflow.call!(shipment)
    document = create(:master_agreement_document, organization: org, master_agreement: agreement)
    create(:master_agreement_extracted_value,
           organization: org,
           master_agreement: agreement,
           master_agreement_document: document,
           field_key: "payment_terms",
           raw_value: "2% 15 Net 30 Days",
           review_status: "confirmed")

    ContractExtraction::SyncReviewedValues.call!(agreement)

    assert_equal "2% 15 Net 30 Days", agreement.reload.payment_terms
    workflow_document = agreement.shipment_documents.joins(:document_template).find_by!(document_templates: { code: "master_agreement" })
    field = org.document_field_definitions.find_by!(key: "payment_terms")
    value = workflow_document.shipment_document_field_values.find_by!(document_field_definition: field)
    assert_equal "2% 15 Net 30 Days", value.raw_value
    assert value.confirmed?
  end
end
