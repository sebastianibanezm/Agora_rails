# Agora Architecture

Agora is a Rails 8 application for export-document workflow orchestration. The
core design has two layers:

- **Template layer**: organization-owned definitions of what the export workflow
  should require.
- **Runtime layer**: operational buyer, contract, purchase order, shipment, and
  shipment document records created during real work.

This split lets each organization configure its expected document graph once,
then instantiate that graph repeatedly for shipments.

## System Shape

```mermaid
flowchart TD
  Org["Organization"]
  Phase["WorkflowPhase"]
  Template["DocumentTemplate"]
  TemplateField["DocumentTemplateField"]
  Field["DocumentFieldDefinition"]
  TemplateDependency["DocumentTemplateDependency"]
  Rule["SourceOfTruthRule"]
  Target["SourceOfTruthRuleTarget"]

  Partner["TradingPartner"]
  Agreement["MasterAgreement"]
  PO["PurchaseOrder"]
  POLine["PurchaseOrderLine"]
  Shipment["Shipment"]
  Lot["ShipmentLot"]
  Container["ShipmentContainer"]
  RuntimeDoc["ShipmentDocument"]
  RuntimeValue["ShipmentDocumentFieldValue"]
  RuntimeDependency["ShipmentDocumentDependency"]
  Check["SourceOfTruthCheck"]

  Org --> Phase
  Phase --> Template
  Template --> TemplateField
  Field --> TemplateField
  Template --> TemplateDependency
  Rule --> Target
  Field --> Rule

  Org --> Partner
  Partner --> Agreement
  Agreement --> PO
  PO --> POLine
  PO --> Shipment
  Shipment --> Lot
  Shipment --> Container
  Shipment --> RuntimeDoc
  Template --> RuntimeDoc
  RuntimeDoc --> RuntimeValue
  Field --> RuntimeValue
  RuntimeDoc --> RuntimeDependency
  Rule --> Check
  RuntimeDoc --> Check
```

## Template Layer

The template layer is seeded for every organization by `SeedWorkflowTemplates`.
It defines:

- `WorkflowPhase`: ordered workflow sections such as booking, loading, customs,
  and post-shipment collection.
- `DocumentTemplate`: reusable document definitions, including type,
  obligation, criticality, destination filters, generator roles, receiver roles,
  and grain.
- `DocumentTemplateDependency`: directed prerequisite edges between templates.
- `DocumentFieldDefinition`: reusable field keys such as consignee, incoterm,
  net weight, container number, and invoice amount.
- `DocumentTemplateField`: fields required by each document template.
- `SourceOfTruthRule`: which template is authoritative for a field.
- `SourceOfTruthRuleTarget`: which templates should be checked against that
  authoritative value.

Template records belong to an organization and are managed primarily through
Avo.

## Runtime Layer

The runtime layer follows the operational hierarchy:

```text
TradingPartner
  -> MasterAgreement
      -> PurchaseOrder
          -> Shipment
              -> ShipmentDocument
```

Additional runtime children support the document grains defined in the template
layer:

- `PurchaseOrderLine` supports `sku_producto` templates.
- `ShipmentLot` supports `lote` templates.
- `ShipmentContainer` supports `contenedor` templates.
- `ShipmentDocumentFieldValue` stores values for runtime documents.
- `ShipmentDocumentDependency` stores runtime prerequisite edges.
- `SourceOfTruthCheck` stores runtime consistency results.

All operational models are organization-owned and use `acts_as_tenant` where
appropriate. Critical models also use PaperTrail.

## Workflow Generation

`CreateShipmentWorkflow.call(shipment)` instantiates active document templates
for a shipment. The service is idempotent and safe to call multiple times.

Document template grain maps to runtime object as follows:

| Template grain | Runtime documentable |
|---|---|
| `relacion_comercial` | Shipment purchase order's `MasterAgreement` |
| `po` | Shipment `PurchaseOrder` |
| `sku_producto` | Shipment purchase order's `PurchaseOrderLine` records |
| `embarque` | `Shipment` |
| `lote` | `ShipmentLot` records |
| `contenedor` | `ShipmentContainer` records |
| `set_documentario` | `Shipment` |

Generation is triggered when a shipment is created. Adding lots or containers
also refreshes the workflow so child-grain documents are created.

The workflow service also:

- skips inactive templates;
- applies template destination filters;
- includes `marine_insurance` only for CIF shipments;
- creates blank runtime field values for configured template fields;
- pre-fills only unambiguous scalar values;
- builds runtime dependency edges from template dependencies;
- recalculates runtime document and shipment status.

## Dependency And Status Lifecycle

`BuildShipmentDocumentDependencies.call(shipment)` converts
`DocumentTemplateDependency` records into `ShipmentDocumentDependency` records.

For Phase 2, every dependent document instance depends on every prerequisite
document instance for the prerequisite template.

`RecalculateShipmentDocumentStatus.call(shipment_document)` updates runtime
dependency edges and document status:

- prerequisite approved or waived -> dependency becomes `satisfied`;
- open prerequisite -> dependent document remains `blocked`;
- no open prerequisites -> dependent document becomes or remains `pending`;
- approved, waived, and rejected documents are terminal for recalculation.

Shipment status is derived from required document readiness unless the shipment
is already in a terminal operational state.

## Source-Of-Truth Validation

`ValidateShipmentSourceOfTruth.call(shipment)` applies `SourceOfTruthRule`
records to runtime shipment documents.

For each rule, Agora compares the authoritative document field value with the
target document field value and persists a `SourceOfTruthCheck`:

- `matched`: expected and actual values are equal.
- `mismatch`: expected and actual values differ.

Phase 2 does not auto-correct target document values. Checks are persisted so
operators can review inconsistencies and decide the appropriate correction.

## Tenant Boundary And Authorization

Tenant routes live under `/:org_slug`. `ApplicationController` sets
`Current.organization` from the path and verifies that the signed-in user belongs
to that organization.

Authorization uses Pundit policies backed by the app's RBAC model:

- `Permission(resource, action)` is the permission catalog.
- `Role` belongs to an organization and has many permissions.
- `User` belongs to an organization and role.
- `user.can?(resource, action)` checks assigned role permissions.

Avo lives at `/admin` and is for superadmin/backoffice access. It uses its own
layout and must not include the app's Vite assets.

## Frontend Boundary

The product UI uses Inertia + React. Phase 2 tenant UI is intentionally narrow:

- shipment index;
- shipment detail/checklist;
- document approve/waive actions;
- source-of-truth validation trigger.

Creation and editing of trading partners, agreements, purchase orders,
shipments, lots, and containers is Avo-first in Phase 2.

All user-facing text in the tenant UI should be Spanish.

## Verification

Use:

```bash
bin/rails db:migrate
bin/rails test
npm run build
npx tsc --noEmit
```

The application expects Ruby 3.3.x. On this machine, Homebrew `ruby@3.3` is
linked so plain `bin/rails` commands use a Rails-compatible runtime.
