export type GraphScope = "purchase_order" | "items" | "customer" | "market"

export interface GraphBox {
  x: number
  y: number
  w: number
  h: number
}

export interface GraphCategory {
  id: GraphScope
  label: string
  icon: string
  blurb: string
  count: number
  enabled: boolean
}

export interface GraphField {
  id: number
  name: string
  key: string
  raw_value?: string | null
  value?: unknown
  source: string
  confirmed: boolean
}

export interface GraphBlockedBy {
  id: number
  graph_id: string
  label: string
}

export interface GraphDocument {
  id: number
  graph_id: string
  label: string
  short: string
  type: string
  status: string
  severity: "ok" | "info" | "watch" | "crit"
  obligation: string
  criticality: string
  grain: string
  assigned_role?: string | null
  documentable_type: string
  documentable_id: number
  scope: GraphScope
  deps: string[]
  ext?: string | null
  issued_by?: string | null
  due_on?: string | null
  completed_at?: string | null
  fields: GraphField[]
  blocked_by: GraphBlockedBy[]
}

export interface GraphDependency {
  id: string
  from: string
  to: string
  status: string
}

export interface ExternalSource {
  id: string
  name: string
  code: string
  kind: string
  sla: string
  documents_count: number
}

export interface GraphRoot {
  id: string
  label: string
  status: string
  buyer: string
  po_number: string
  route?: string
  etd?: string
  destination_country?: string
  booking_number?: string
  vessel?: string
  voyage?: string
}

export interface GraphPurchaseOrder {
  id: string
  label: string
  status: string
  buyer: string
  incoterm?: string | null
  currency?: string | null
  total_amount?: string | number | null
  issued_on?: string | null
  required_ship_on?: string | null
  destination_country?: string | null
  consignee_name?: string | null
  documents_count: number
}

export interface GraphItem {
  id: string
  label: string
  sku: string
  quantity?: string | null
  unit?: string | null
  packaging?: string | null
  hs_code?: string | null
  documents_count: number
}

export interface GraphCustomer {
  id: string
  label: string
  legal_name?: string | null
  country?: string | null
  partner_type?: string | null
  tax_identifier?: string | null
  email?: string | null
  phone?: string | null
  master_agreement?: string | null
  agreement_number?: string | null
  payment_terms?: string | null
  documents_count: number
}

export interface GraphMarket {
  id: string
  label: string
  region: string
  authority: string
  documents_count: number
}

export interface SourceOfTruthCheck {
  id: number
  status: string
  field_name: string
  expected_value?: unknown
  actual_value?: unknown
  failure_action: string
  authoritative_document: string
  target_document: string
}

export interface ShipmentGraph {
  root: GraphRoot
  categories: GraphCategory[]
  purchase_order: GraphPurchaseOrder
  items: GraphItem[]
  customer: GraphCustomer
  market: GraphMarket
  documents: GraphDocument[]
  dependencies: GraphDependency[]
  external_sources: ExternalSource[]
  source_of_truth_checks: SourceOfTruthCheck[]
}

export type GraphSelection =
  | { kind: "root"; id: string }
  | { kind: "category"; id: GraphScope }
  | { kind: "purchase_order"; id: string }
  | { kind: "item"; id: string }
  | { kind: "customer"; id: string }
  | { kind: "market"; id: string }
  | { kind: "doc"; id: string }
  | { kind: "ext"; id: string }

export interface ChainSelection {
  type: "doc" | "ext"
  id: string
}
