# Operational Workflow

This document describes how Agora turns configured document templates into real
shipment work.

## Business Hierarchy

Agora models export operations with this hierarchy:

```text
Trading Partner / Buyer
  -> Master Agreement / Contract
      -> Contract Packet Documents / Extracted Terms
      -> Purchase Order
          -> Shipment / Embarque
              -> Shipment Documents
```

The hierarchy is intentionally explicit. A purchase order is not just a
document; it is an operational record that can have lines and shipments. A
shipment is not just a folder; it is the runtime container for the document
checklist, dependencies, field values, and source-of-truth checks.

## Operational Records

| Model | Purpose |
|---|---|
| `TradingPartner` | Buyer or other trade partner master data. |
| `MasterAgreement` | Contractual terms with a trading partner. |
| `MasterAgreementDocument` | Source contract PDF, schedule, exhibit, or certificate attached to a master agreement. |
| `MasterAgreementExtractedValue` | Field-level AI extraction output with provenance, confidence, and review status. |
| `MasterAgreementSchedule` | Reviewed schedule terms such as payment, lead time, delivery, product category, participating companies, distributors, pallets, and unsaleables. |
| `MasterAgreementDeliveryLocation` | Schedule delivery destination extracted from the packet. |
| `MasterAgreementProductPriceLine` | Schedule pricing row extracted from text or image tables. |
| `MasterAgreementParty`, `MasterAgreementContact`, `MasterAgreementSigner`, `MasterAgreementClause` | Parties, contacts, DocuSign execution data, and clause obligations extracted from packet documents. |
| `PurchaseOrder` | Commercial order under a master agreement. |
| `PurchaseOrderLine` | Product/SKU detail for a purchase order. |
| `Shipment` | Operational embarque under a purchase order. |
| `ShipmentLot` | Lot-level shipment detail. |
| `ShipmentContainer` | Container-level shipment detail. |
| `ShipmentDocument` | Runtime instance of a document template. |
| `ShipmentDocumentFieldValue` | Runtime value for a template-defined field. |
| `ShipmentDocumentDependency` | Runtime prerequisite edge between documents. |
| `SourceOfTruthCheck` | Persisted result of field consistency validation. |

## Contract Packet Lifecycle

The contract packet lifecycle sits before and beside shipment workflow
generation:

1. A user uploads one or more PDFs to the master agreement detail page.
2. The upload creates `MasterAgreementDocument` records with a `document_kind`
   such as `agreement`, `schedule`, `exhibit`, or `certificate`.
3. A user queues extraction. `MasterAgreementExtractionJob` calls
   `ContractExtraction::ExtractMasterAgreementDocument`.
4. The extraction service stores raw extracted JSON plus normalized parties,
   contacts, signers, schedules, delivery locations, pricing lines, clauses, and
   extracted values.
5. Extracted records start as `pending_review`.
6. A user confirms or corrects extracted fields, price lines, or the whole
   document batch.
7. `ContractExtraction::SyncReviewedValues` syncs confirmed terms into
   `MasterAgreement` attributes and agreement-level workflow document fields.

Only confirmed extraction data is operationally authoritative. Pending AI output
is visible for review but must not drive downstream documents.

Common confirmed terms include:

- customer/vendor legal names;
- contract and schedule dates;
- payment terms;
- delivery terms and designated locations;
- lead time;
- product/category, specifications reference, case pack, UOM, unit cost;
- pallet and unsaleables requirements;
- recall contacts and compliance obligations.

## Shipment Creation Lifecycle

When a `Shipment` is created, its `after_create` callback calls:

```ruby
CreateShipmentWorkflow.call(shipment)
```

That service:

1. Finds active document templates for the shipment organization.
2. Filters templates by destination and CIF insurance rules.
3. Maps each template to one or more runtime documentable records.
4. Creates missing `ShipmentDocument` records.
5. Creates missing `ShipmentDocumentFieldValue` records.
6. Builds runtime dependencies from template dependencies.
7. Recalculates document and shipment status.

The service is idempotent. Re-running it should not duplicate documents, field
values, or dependency edges.

When a configured field matches a confirmed contract term, the field value is
prefilled from the master agreement extraction layer. Examples include payment
terms, delivery terms, delivery locations, lead time, specifications reference,
pallet requirements, unsaleables terms, recall contacts, and compliance
requirements.

## Lot And Container Lifecycle

Some document templates are generated per child record:

- `lote` templates are generated for `ShipmentLot` records.
- `contenedor` templates are generated for `ShipmentContainer` records.

When a lot or container is created, it refreshes the shipment workflow by calling
`CreateShipmentWorkflow.call(shipment)`. The service uses fresh database queries
for lots and containers so newly-created child records are visible even when the
shipment object has cached associations.

## Document Grain Mapping

| Grain | Example templates | Runtime scope |
|---|---|---|
| `relacion_comercial` | Master Agreement | One shared document per master agreement/template. |
| `po` | Purchase Order, production program entry | One document per shipment purchase order. |
| `sku_producto` | Product Spec / Packaging / Label | One document per PO line. |
| `embarque` | Shipping Instruction, Booking, Invoice, Packing List, BL | One document per shipment. |
| `lote` | CoA, work order, lot assignment | One document per shipment lot. |
| `contenedor` | Loading Report + VGM, Dispatch Guide | One document per shipment container. |
| `set_documentario` | Documentary Set | One document per shipment. |

If a grain has no runtime records yet, Agora creates no document for that grain
until the relevant runtime record exists.

## Document Statuses

`ShipmentDocument.status` values:

| Status | Meaning |
|---|---|
| `not_started` | Document exists but work has not begun. |
| `blocked` | At least one prerequisite is still open. |
| `pending` | Document can be worked on. |
| `in_review` | Document is under review. |
| `approved` | Document is accepted. |
| `rejected` | Document was rejected. |
| `waived` | Document was intentionally skipped by exception. |

`approved`, `rejected`, and `waived` are terminal for automatic status
recalculation.

## Shipment Statuses

`Shipment.status` values:

| Status | Meaning |
|---|---|
| `planning` | Shipment has been created but workflow readiness is not complete. |
| `documents_pending` | Required documents are not all approved or waived. |
| `ready_to_ship` | Required documents are approved or waived. |
| `shipped` | Shipment has departed. |
| `post_zarpe` | Shipment is in post-departure follow-up. |
| `closed` | Operational workflow is complete. |
| `cancelled` | Shipment is cancelled. |

Document recalculation can update planning shipments to `documents_pending` or
`ready_to_ship`. It does not override terminal operational states.

## Dependency Rules

Template dependency edges are copied to runtime dependency edges by:

```ruby
BuildShipmentDocumentDependencies.call(shipment)
```

For Phase 2, dependency expansion is intentionally broad: every dependent
shipment document instance depends on every prerequisite shipment document
instance for the prerequisite template.

A dependency is:

- `open` while the prerequisite document is not approved or waived;
- `satisfied` once the prerequisite is approved or waived;
- `waived` if the dependency itself is manually waived.

## Source-Of-Truth Checks

Source-of-truth rules define which document template is authoritative for a
field. Runtime validation is performed by:

```ruby
ValidateShipmentSourceOfTruth.call(shipment)
```

The service persists `SourceOfTruthCheck` records with:

- authoritative shipment document;
- target shipment document;
- checked field;
- expected value;
- actual value;
- status;
- failure action.

Validation is observational in Phase 2. It records mismatches but does not
rewrite field values.

The current seed catalog includes agreement/schedule source-of-truth fields in
addition to shipment operational fields. For example, the `master_agreement`
template is authoritative for payment terms, delivery terms, and delivery
locations where those values appear in commercial invoices, documentary sets,
payment reconciliation, shipping instructions, BL matrices, or bills of lading.

## Avo Versus Tenant UI

Phase 2 deliberately splits responsibility:

- **Avo** owns CRUD for trading partners, agreements, purchase orders, purchase
  order lines, shipments, lots, containers, and low-level runtime records.
- **Tenant UI** starts from the master agreement and owns document operations:
  - master agreement list;
  - master agreement detail with contract packet upload, extraction, review,
    purchase orders, and shipments;
  - extracted field correction and confirmation;
  - schedule, contact, signer, delivery location, clause, and pricing row
    visibility;
  - delivered unit cost correction and confirmation for extracted pricing rows;
  - shared contract-document status;
  - shipment detail/checklist;
  - approve document;
  - waive document;
  - run source-of-truth validation.

This keeps Phase 2 operationally useful without building a full tenant CRUD
surface before the workflow engine is stable.

## Current Limitations

These are known hardening areas rather than architecture defects:

- Runtime workflow generation should remain transactionally safe and resilient
  under concurrent lot/container creation.
- Runtime dependency recalculation must guard against cycles created by template
  misconfiguration.
- Pundit scopes should remain organization-filtered as defense in depth.
- Shipment index should stay paginated as data volume grows.
- AI extraction should remain provider-agnostic and mocked in tests.
- Image-only pricing tables depend on the AI endpoint and optional local page
  rendering support; pending rows require human review before use.
- Tenant CRUD for operational records is intentionally deferred.

See `docs/architecture.md` for the system-wide model and service overview.
See `docs/master-agreement-extraction.md` for extraction-specific behavior.
