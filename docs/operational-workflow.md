# Operational Workflow

This document describes how Agora turns configured document templates into real
shipment work.

## Business Hierarchy

Agora models export operations with this hierarchy:

```text
Trading Partner / Buyer
  -> Master Agreement / Contract
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
| `PurchaseOrder` | Commercial order under a master agreement. |
| `PurchaseOrderLine` | Product/SKU detail for a purchase order. |
| `Shipment` | Operational embarque under a purchase order. |
| `ShipmentLot` | Lot-level shipment detail. |
| `ShipmentContainer` | Container-level shipment detail. |
| `ShipmentDocument` | Runtime instance of a document template. |
| `ShipmentDocumentFieldValue` | Runtime value for a template-defined field. |
| `ShipmentDocumentDependency` | Runtime prerequisite edge between documents. |
| `SourceOfTruthCheck` | Persisted result of field consistency validation. |

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
| `relacion_comercial` | Master Agreement | One document per shipment agreement. |
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

## Avo Versus Tenant UI

Phase 2 deliberately splits responsibility:

- **Avo** owns CRUD for trading partners, agreements, purchase orders, purchase
  order lines, shipments, lots, containers, and low-level runtime records.
- **Tenant UI** owns shipment visibility and document operations:
  - shipment list;
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
- Tenant CRUD for operational records is intentionally deferred.

See `docs/architecture.md` for the system-wide model and service overview.
