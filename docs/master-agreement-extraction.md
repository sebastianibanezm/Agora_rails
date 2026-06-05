# Master Agreement Extraction

Agora stores master agreements as operational contracts and as source document
packets. The packet layer lets uploaded PDFs live in the app, be extracted by an
AI service, reviewed by a user, and then feed confirmed values into downstream
shipment documents.

## Data Model

`MasterAgreement` remains the contract record under a `TradingPartner`.
`MasterAgreement#contract_file` is kept for backward compatibility, but new
uploads should use `MasterAgreementDocument`.

| Model | Purpose |
|---|---|
| `MasterAgreementDocument` | One source PDF or packet document, such as agreement, schedule, exhibit, or certificate. Stores file, extraction status, extracted text, extracted JSON, DocuSign metadata, and review metadata. |
| `MasterAgreementExtractedValue` | Field-level AI output with `field_key`, raw value, normalized JSON, source page/label, confidence, and review status. |
| `MasterAgreementParty` | Extracted customer, vendor, participating company, distributor, or other party. |
| `MasterAgreementContact` | Notice, copy, emergency, recall, QA, legal, and category-manager contacts. |
| `MasterAgreementSigner` | DocuSign signer metadata, including title, company, email, timestamps, and IP address. |
| `MasterAgreementSchedule` | Schedule-level commercial terms: product category, term dates, payment terms, lead time, delivery terms, specifications reference, incentives, unsaleables, participating companies, distributors, pallet requirements, and pricing adjustment terms. |
| `MasterAgreementDeliveryLocation` | Customer delivery locations attached to a schedule. |
| `MasterAgreementProductPriceLine` | Product price rows with participating company, product description, case pack, size, UOM, delivered unit cost, currency, source page, confidence, and review status. |
| `MasterAgreementClause` | Clause summaries and obligations, with section number, title, source page, confidence, and review status. |

Every extraction record is organization-owned, tenant-checked, paper-trailed,
and reviewable. Review statuses are:

| Status | Meaning |
|---|---|
| `pending_review` | AI output is visible but not authoritative. |
| `confirmed` | A user accepted or corrected the value. Confirmed records can sync into operational fields. |
| `rejected` | A user rejected the extraction. Rejected records remain auditable but should not drive documents. |

## Extraction Flow

1. A user uploads a PDF on the master agreement detail page.
2. `MasterAgreementDocumentsController#create` creates a
   `MasterAgreementDocument` and can enqueue extraction immediately.
3. `MasterAgreementExtractionJob` calls
   `ContractExtraction::ExtractMasterAgreementDocument`.
4. `ContractExtraction::PdfContent` downloads the Active Storage file, extracts
   text with `pdf-reader`, and includes sparse page images when `pdftoppm` is
   available for image-only pages.
5. `ContractExtraction::AiClient` sends page text, optional page images, the
   original PDF bytes, and extraction instructions to the configured AI endpoint.
6. The extraction service persists normalized packet records and the original
   extraction JSON, then marks the document `needs_review`.
7. A user confirms or corrects extracted fields, price rows, or the document
   batch from the UI.
8. `ContractExtraction::SyncReviewedValues` copies confirmed terms into
   `MasterAgreement` attributes and agreement-level
   `ShipmentDocumentFieldValue` records when matching field definitions exist.

`MasterAgreementDocument.extraction_status` values are:

| Status | Meaning |
|---|---|
| `not_started` | No extraction has been requested. |
| `pending` | Extraction has been queued. |
| `processing` | Extraction is running. |
| `needs_review` | Extraction succeeded and user review is required. |
| `succeeded` | Reserved for fully automated success. Current UI normally uses `needs_review`. |
| `failed` | Extraction failed; `extraction_error` stores the failure message. |

## AI Provider Configuration

The app does not hard-code a specific AI vendor. It posts JSON to the configured
endpoint.

| Variable | Purpose |
|---|---|
| `MASTER_AGREEMENT_EXTRACTION_ENDPOINT` | HTTPS endpoint that accepts the extraction payload and returns strict JSON. |
| `MASTER_AGREEMENT_EXTRACTION_API_KEY` | Optional bearer token. |
| `MASTER_AGREEMENT_EXTRACTION_MODEL` | Optional model or deployment name included in the payload. |

The expected response can either be the extraction JSON directly or an object
with an `extraction` key. Tests use a stub client and do not call the network.

## Confirmed Contract Data

The current seed catalog includes agreement and schedule fields that can feed
downstream documents:

- party names: `customer_legal_name`, `vendor_legal_name`, `shipper_name`;
- dates: `contract_effective_date`, `contract_expiration_date`,
  `schedule_effective_date`, `schedule_expiration_date`,
  `first_delivery_date`;
- commercial terms: `payment_terms`, `delivery_terms`, `lead_time_days`,
  `service_level_commitment`, `unit_price`, `case_pack`, `uom`;
- operating references: `delivery_locations`, `specifications_reference`,
  `pallet_requirements`, `unsaleables_terms`, `recall_contacts`,
  `compliance_requirements`.

Confirmed values are authoritative for operational document prefill and
source-of-truth checks. Pending AI output is not authoritative.

## UI Surface

The master agreement detail page contains the contract packet panel:

- upload agreement/schedule/exhibit/certificate PDFs;
- queue extraction;
- see extraction and DocuSign status;
- confirm an extracted document batch;
- correct and confirm individual extracted fields;
- correct and confirm delivered unit costs on pricing rows;
- inspect schedules, contacts, signers, parties, locations, price lines, and
  clauses.

The shipment workflow graph remains separate. It consumes confirmed contract
terms through agreement-level `ShipmentDocumentFieldValue` records.
