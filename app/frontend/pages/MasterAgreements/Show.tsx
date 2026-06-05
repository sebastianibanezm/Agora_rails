import { Link, router } from "@inertiajs/react"
import { useMemo, useState } from "react"
import type { CSSProperties, FormEvent, ReactNode } from "react"
import { AppShell } from "@/components/agora/AppShell"
import { Icon } from "@/components/document_graph/icons"
import "@/components/document_graph/styles.css"

type Lens = "pos" | "items" | "customer" | "market"
type PanelSelection = { kind: "agreement" } | { kind: "po"; id: number } | null

interface Agreement {
  id: number
  agreement_number: string
  name: string
  status: string
  effective_on?: string | null
  expires_on?: string | null
  incoterm?: string | null
  payment_terms?: string | null
  currency?: string | null
  total_amount?: string | number | null
  trading_partner: {
    name: string
    legal_name?: string | null
    country?: string | null
  }
  counts: {
    purchase_orders: number
    shipments: number
    contract_documents: number
  }
  contract_document_progress: {
    approved: number
    total: number
  }
}

interface PurchaseOrder {
  id: number
  po_number: string
  status: string
  issued_on?: string | null
  required_ship_on?: string | null
  destination_country?: string | null
  incoterm?: string | null
  total_amount?: string | number | null
  currency?: string | null
  lines_count: number
  items: Item[]
  shipments: Shipment[]
}

interface Item {
  id: number
  sku: string
  label: string
  quantity?: string | null
  unit?: string | null
  packaging?: string | null
  hs_code?: string | null
  documents_count: number
  documents: ContractDocument[]
}

interface Shipment {
  id: number
  shipment_number: string
  status: string
  etd?: string | null
  destination_country?: string | null
  pol?: string | null
  pod?: string | null
  booking_number?: string | null
  document_progress: {
    approved: number
    total: number
  }
  documents: ContractDocument[]
}

interface ContractDocument {
  id: number
  name: string
  code: string
  status: string
  obligation: string
  criticality: string
  grain?: string
  documentable_type?: string
  assigned_role?: string | null
  deps?: number[]
  blocked_by?: Array<{
    id: number
    label: string
    status: string
  }>
  fields: Array<{
    id: number
    name: string
    raw_value?: string | null
    value?: unknown
    source: string
    confirmed: boolean
  }>
}

interface ContractPacketDocument {
  id: number
  title: string
  document_kind: string
  effective_on?: string | null
  expires_on?: string | null
  extraction_status: string
  extraction_error?: string | null
  reviewed_at?: string | null
  file_name?: string | null
  docusign: {
    envelope_id?: string | null
    status?: string | null
    subject?: string | null
    originator_name?: string | null
    originator_email?: string | null
    time_zone?: string | null
  }
  counts: {
    extracted_values: number
    schedules: number
    clauses: number
  }
}

interface ExtractedValue {
  id: number
  document_id: number
  field_key: string
  label: string
  raw_value?: string | null
  source_label?: string | null
  page_number?: number | null
  confidence?: number | null
  review_status: string
}

interface ContractParty {
  id: number
  party_role: string
  name: string
  legal_name?: string | null
  state_of_incorporation?: string | null
  confidence?: number | null
  review_status: string
}

interface ContractContact {
  id: number
  contact_type: string
  party_role?: string | null
  name?: string | null
  title?: string | null
  phone?: string | null
  email?: string | null
  address?: string | null
  confidence?: number | null
  review_status: string
}

interface ContractSigner {
  id: number
  party_role: string
  name: string
  email?: string | null
  title?: string | null
  company?: string | null
  signed_at?: string | null
  ip_address?: string | null
  review_status: string
}

interface ContractSchedule {
  id: number
  document_id: number
  title: string
  product_category?: string | null
  currency?: string | null
  effective_on?: string | null
  expires_on?: string | null
  first_delivery_on?: string | null
  payment_terms?: string | null
  lead_time_days?: number | null
  lead_time_description?: string | null
  delivery_terms?: string | null
  specifications_reference?: string | null
  incentives?: string | null
  unsaleables_terms?: string | null
  pricing_adjustment_terms?: string | null
  participating_companies: string[]
  distributors: string[]
  pallet_requirements: string[]
  review_status: string
  delivery_locations: ContractDeliveryLocation[]
  product_price_lines: ContractPriceLine[]
}

interface ContractDeliveryLocation {
  id: number
  code?: string | null
  name: string
  address?: string | null
  city?: string | null
  state_region?: string | null
  postal_code?: string | null
  country?: string | null
  review_status: string
}

interface ContractPriceLine {
  id: number
  participating_company: string
  product_description: string
  case_pack?: number | null
  size?: string | null
  uom?: string | null
  unit_cost_delivered?: string | null
  currency?: string | null
  source_page?: number | null
  confidence?: number | null
  review_status: string
}

interface ContractClause {
  id: number
  document_id: number
  section_number: string
  title: string
  summary?: string | null
  review_status: string
}

interface ContractPacket {
  documents: ContractPacketDocument[]
  extracted_values: ExtractedValue[]
  parties: ContractParty[]
  contacts: ContractContact[]
  signers: ContractSigner[]
  schedules: ContractSchedule[]
  clauses: ContractClause[]
}

interface Props {
  org_slug: string
  agreement: Agreement
  purchase_orders: PurchaseOrder[]
  contract_documents: ContractDocument[]
  contract_packet: ContractPacket
}

interface Point {
  x: number
  y: number
}

interface Box {
  x: number
  y: number
  w: number
  h: number
}

interface DocLayout {
  boxes: Map<number, Box>
  stacks: Map<number, ContractDocument[]>
  stackIndexes: number[]
  edges: Array<{
    id: string
    fromId: number
    toId: number
    d: string
  }>
  width: number
  height: number
}

const LENSES: Array<{ id: Lens; label: string; blurb: string; icon: keyof typeof Icon }> = [
  { id: "pos", label: "Purchase Orders", blurb: "Shipments, routes & POs", icon: "po" },
  { id: "items", label: "Items", blurb: "Varieties & SKUs sold", icon: "apple" },
  { id: "customer", label: "Customer", blurb: "Buyer onboarding & terms", icon: "user" },
  { id: "market", label: "Market", blurb: "Destination regulations", icon: "globe" },
]

const DOC_W = 220
const DOC_H = 114
const DOC_COL_GAP = 48
const DOC_ROW_GAP = 16
const DOC_TOP = 54
const DOC_LEFT = 28
const DOC_VISIBLE_COLUMNS = 4

export default function MasterAgreementsShow({ org_slug, agreement, purchase_orders, contract_documents, contract_packet }: Props) {
  const [lens, setLens] = useState<Lens | null>(null)
  const [selectedPoId, setSelectedPoId] = useState<number | null>(null)
  const [selectedItemId, setSelectedItemId] = useState<number | null>(null)
  const [selectedDocumentId, setSelectedDocumentId] = useState<number | null>(null)
  const [panelSelection, setPanelSelection] = useState<PanelSelection>(null)
  const items = useMemo(() => purchase_orders.flatMap((purchaseOrder) => purchaseOrder.items || []), [purchase_orders])
  const marketDocuments = useMemo(() => uniqueDocuments(
    purchase_orders
      .flatMap((purchaseOrder) => purchaseOrder.shipments)
      .flatMap((shipment) => shipment.documents)
      .filter((document) => ["Shipment", "ShipmentContainer"].includes(document.documentable_type || "") || ["embarque", "contenedor", "set_documentario"].includes(document.grain || ""))
  ), [purchase_orders])
  const selectedPo = purchase_orders.find((purchaseOrder) => purchaseOrder.id === selectedPoId)
  const selectedItem = items.find((item) => item.id === selectedItemId)
  const activeDocuments = documentsForLens(lens, selectedPo, selectedItem, contract_documents, marketDocuments)
  const selectedDocument = activeDocuments.find((document) => document.id === selectedDocumentId)
  const panelPurchaseOrder = panelSelection?.kind === "po" ? purchase_orders.find((purchaseOrder) => purchaseOrder.id === panelSelection.id) : undefined
  const panelOpen = Boolean(selectedDocument || panelSelection)
  const scopeLabel = scopeLabelFor(lens, selectedPo, selectedItem, agreement, purchase_orders)

  function chooseLens(nextLens: Lens) {
    setLens(lens === nextLens ? null : nextLens)
    setSelectedPoId(null)
    setSelectedItemId(null)
    setSelectedDocumentId(null)
    setPanelSelection(null)
  }

  function choosePurchaseOrder(purchaseOrderId: number) {
    setLens("pos")
    setSelectedPoId(purchaseOrderId)
    setSelectedDocumentId(null)
    setPanelSelection({ kind: "po", id: purchaseOrderId })
  }

  function chooseItem(itemId: number) {
    setSelectedItemId(selectedItemId === itemId ? null : itemId)
    setSelectedDocumentId(null)
    setPanelSelection(null)
  }

  function approve(documentId: number) {
    router.post(`/${org_slug}/shipment_documents/${documentId}/approve`, {}, { preserveScroll: true })
  }

  function waive(documentId: number) {
    router.post(`/${org_slug}/shipment_documents/${documentId}/waive`, {}, { preserveScroll: true })
  }

  return (
    <AppShell orgSlug={org_slug}>
      <section className={`adg-flow-surface${panelOpen ? " has-doc-panel" : ""}`}>
        <header className="adg-flow-head">
          <div className="adg-flow-contract-mark"><Icon.contract /></div>
          <div>
            <div className="adg-flow-id">{agreement.agreement_number}</div>
            <h1>{agreement.name}</h1>
          </div>
          <div className="adg-flow-separator" />
          <div className="adg-flow-party">
            <span>{agreement.trading_partner.legal_name || agreement.trading_partner.name}</span>
            <strong>{[agreement.trading_partner.name, flagForCountry(agreement.trading_partner.country)].filter(Boolean).join(" ")}</strong>
          </div>
          <div className="adg-flow-meta">
            <span>Flow · Contract</span>
            <strong>{purchase_orders.length} PO · {items.length} items · {contract_documents.length} docs</strong>
          </div>
          <Link className="adg-icon-btn" href={`/${org_slug}/master_agreements`} title="Close"><Icon.close /></Link>
        </header>

        <div className="adg-flow-body">
          <section className="adg-reference-graph">
            <ContractPacketPanel orgSlug={org_slug} agreement={agreement} packet={contract_packet} />

            <button className={`adg-flow-contract-card adg-reference-contract sev-${severityForAgreement(agreement)}`} type="button" onClick={() => {
              setSelectedDocumentId(null)
              setPanelSelection({ kind: "agreement" })
            }}>
              <div className="adg-nc-top">
                <div className="adg-nc-icon"><Icon.contract /></div>
                <div>
                  <div className="adg-nc-id">{agreement.agreement_number}</div>
                  <div className="adg-nc-name">{agreement.name}</div>
                </div>
              </div>
              <div className="adg-nc-meta">
                <span>{agreement.incoterm || "Incoterm"}</span>
                <span>{agreement.currency || "USD"}</span>
                <span>{purchase_orders.length} PO</span>
                <span>exp {shortDate(agreement.expires_on) || "--"}</span>
              </div>
            </button>

            <div className="adg-flow-label">Explore by · {LENSES.length}</div>
            <div className="adg-lens-grid">
              {LENSES.map((candidate) => {
                const LensIcon = Icon[candidate.icon]
                const count = countForLens(candidate.id, purchase_orders, items, contract_documents, marketDocuments)
                return (
                  <button
                    className={`adg-lens-card cat-${candidate.id}${lens === candidate.id ? " active" : ""}${lens && lens !== candidate.id ? " dim" : ""}`}
                    type="button"
                    onClick={() => chooseLens(candidate.id)}
                    key={candidate.id}
                  >
                    <div className="adg-cat-top">
                      <div className="adg-cat-icon"><LensIcon /></div>
                      <div className="adg-cat-count">{count}</div>
                    </div>
                    <div className="adg-cat-label">{candidate.label}</div>
                    <div className="adg-cat-blurb">{candidate.blurb}</div>
                  </button>
                )
              })}
            </div>

            {!lens && <div className="adg-flow-hint">Pick a lens to explore this contract</div>}

            {lens === "pos" && (
              <FlowSection label={`Purchase orders · ${purchase_orders.length}`}>
                <div className="adg-po-flow-row">
                  {purchase_orders.map((purchaseOrder) => (
                    <button
                      className={`adg-po-flow-card sev-${severityForPurchaseOrder(purchaseOrder)}${selectedPoId === purchaseOrder.id ? " active" : ""}${selectedPoId && selectedPoId !== purchaseOrder.id ? " dim" : ""}`}
                      type="button"
                      onClick={() => choosePurchaseOrder(purchaseOrder.id)}
                      key={purchaseOrder.id}
                    >
                      <div className="adg-np-top">
                        <span className="adg-np-id">{purchaseOrder.po_number}</span>
                        <span className={`adg-pill ${pillForPurchaseOrder(purchaseOrder.status)}`}><span className="dot" />{labelForPurchaseOrderStatus(purchaseOrder.status)}</span>
                      </div>
                      <div className="adg-np-route">{purchaseOrder.destination_country || "Destino pendiente"}</div>
                      <div className="adg-np-carrier">
                        <span>{purchaseOrder.incoterm || agreement.incoterm || "Incoterm"}</span>
                        <span className="containers">{purchaseOrder.lines_count} items</span>
                      </div>
                      <div className="adg-np-foot">
                        <span>{formatMoney(purchaseOrder.total_amount, purchaseOrder.currency || agreement.currency)}</span>
                        <span className="eta">{purchaseOrder.required_ship_on || purchaseOrder.issued_on || "sin fecha"}</span>
                      </div>
                    </button>
                  ))}
                </div>
                {!selectedPo && <div className="adg-flow-hint">Click a PO to reveal its shipments and documents</div>}
                {selectedPo && <SelectedPo purchaseOrder={selectedPo} />}
              </FlowSection>
            )}

            {lens === "items" && (
              <FlowSection label={`Items · ${items.length}`}>
                <div className="adg-po-flow-row">
                  {items.map((item) => (
                    <button
                      className={`adg-item-flow-card sev-ok${selectedItemId === item.id ? " active" : ""}${selectedItemId && selectedItemId !== item.id ? " dim" : ""}`}
                      type="button"
                      onClick={() => chooseItem(item.id)}
                      key={item.id}
                    >
                      <div className="adg-ni-top">
                        <div className="adg-ni-icon"><Icon.apple /></div>
                        <div className="adg-ni-sku">{item.sku}</div>
                      </div>
                      <div className="adg-ni-name">{item.label}</div>
                      <div className="adg-ni-variety">{[item.quantity, item.unit, item.packaging].filter(Boolean).join(" ") || "Cantidad pendiente"}</div>
                      <div className="adg-ni-foot">
                        <span>{item.hs_code || "HS sin definir"}</span>
                        <span className="docs">{item.documents_count} docs</span>
                      </div>
                    </button>
                  ))}
                </div>
                {!selectedItem && <div className="adg-flow-hint">Click an item to reveal its product documents</div>}
              </FlowSection>
            )}

            {lens === "customer" && (
              <FlowSection label="Customer · 1">
                <article className="adg-info-flow-card adg-node-info-cust">
                  <div className="adg-info-top">
                    <div className="adg-info-avatar"><Icon.user /></div>
                    <div>
                      <div className="adg-info-eye">Cliente · buyer</div>
                      <div className="adg-info-name">{agreement.trading_partner.name}</div>
                      <div className="adg-info-id">{agreement.trading_partner.legal_name || agreement.trading_partner.country || "Contraparte comercial"}</div>
                    </div>
                  </div>
                  <div className="adg-info-desc">
                    Acuerdo maestro {agreement.agreement_number}. Terminos: {agreement.payment_terms || "por confirmar"}.
                  </div>
                  <div className="adg-info-kv">
                    <span><span className="k">Pais</span><span className="v">{agreement.trading_partner.country || "-"}</span></span>
                    <span><span className="k">Incoterm</span><span className="v">{agreement.incoterm || "-"}</span></span>
                    <span><span className="k">Docs</span><span className="v">{contract_documents.length}</span></span>
                  </div>
                </article>
              </FlowSection>
            )}

            {lens === "market" && (
              <FlowSection label={`Market · ${destinationsFor(purchase_orders).length || 1}`}>
                <article className="adg-info-flow-card adg-node-info-mkt">
                  <div className="adg-info-top">
                    <div className="adg-info-avatar"><Icon.globe /></div>
                    <div>
                      <div className="adg-info-eye">Mercado destino</div>
                      <div className="adg-info-name">{destinationsFor(purchase_orders).join(", ") || "Destino por confirmar"}</div>
                      <div className="adg-info-id">Reglas documentarias y fuente de verdad</div>
                    </div>
                  </div>
                  <div className="adg-info-desc">
                    Documentos regulatorios, de embarque y cuadraturas que condicionan la liberacion del flujo.
                  </div>
                  <div className="adg-info-kv">
                    <span><span className="k">Destinos</span><span className="v">{destinationsFor(purchase_orders).length || "-"}</span></span>
                    <span><span className="k">Docs</span><span className="v">{marketDocuments.length}</span></span>
                    <span><span className="k">Control</span><span className="v">SOT</span></span>
                  </div>
                </article>
              </FlowSection>
            )}

            {lens && activeDocuments.length > 0 && (
              <FlowSection label={`Documents · ${activeDocuments.length}`}>
                <DocumentPipeline
                  documents={activeDocuments}
                  selectedDocumentId={selectedDocumentId}
                  onSelectDocument={(documentId) => {
                    setSelectedDocumentId(selectedDocumentId === documentId ? null : documentId)
                    setPanelSelection(null)
                  }}
                />
              </FlowSection>
            )}
          </section>
        </div>
      </section>

      {selectedDocument && (
        <DocumentDrawer
          document={selectedDocument}
          documents={activeDocuments}
          scopeLabel={scopeLabel}
          agreement={agreement}
          onClose={() => setSelectedDocumentId(null)}
          onApprove={approve}
          onWaive={waive}
          onJumpDocument={setSelectedDocumentId}
        />
      )}
      {!selectedDocument && panelSelection?.kind === "agreement" && (
        <AgreementDrawer
          agreement={agreement}
          purchaseOrders={purchase_orders}
          documents={contract_documents}
          onClose={() => setPanelSelection(null)}
          onJumpPurchaseOrder={(purchaseOrderId) => choosePurchaseOrder(purchaseOrderId)}
        />
      )}
      {!selectedDocument && panelSelection?.kind === "po" && panelPurchaseOrder && (
        <PurchaseOrderDrawer
          agreement={agreement}
          purchaseOrder={panelPurchaseOrder}
          onClose={() => setPanelSelection(null)}
        />
      )}
    </AppShell>
  )
}

function ContractPacketPanel({ orgSlug, agreement, packet }: { orgSlug: string; agreement: Agreement; packet: ContractPacket }) {
  const [uploadTitle, setUploadTitle] = useState("")
  const [uploadKind, setUploadKind] = useState("agreement")
  const [uploadFile, setUploadFile] = useState<File | null>(null)
  const [editedValues, setEditedValues] = useState<Record<number, string>>({})
  const [editedPrices, setEditedPrices] = useState<Record<number, string>>({})
  const confirmedValues = packet.extracted_values.filter((value) => value.review_status === "confirmed").length
  const pendingValues = packet.extracted_values.filter((value) => value.review_status === "pending_review").length
  const visibleValues = packet.extracted_values.slice(0, 12)
  const priceLines = packet.schedules.flatMap((schedule) => schedule.product_price_lines)
  const locations = packet.schedules.flatMap((schedule) => schedule.delivery_locations)

  function upload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!uploadFile) return

    const data = new FormData()
    data.append("master_agreement_document[title]", uploadTitle || uploadFile.name)
    data.append("master_agreement_document[document_kind]", uploadKind)
    data.append("master_agreement_document[file]", uploadFile)
    data.append("extract", "1")
    router.post(`/${orgSlug}/master_agreements/${agreement.id}/master_agreement_documents`, data, {
      forceFormData: true,
      preserveScroll: true,
      onSuccess: () => {
        setUploadTitle("")
        setUploadFile(null)
      },
    })
  }

  function queueExtraction(documentId: number) {
    router.post(`/${orgSlug}/master_agreements/${agreement.id}/master_agreement_documents/${documentId}/extract`, {}, { preserveScroll: true })
  }

  function confirmDocument(documentId: number) {
    router.patch(`/${orgSlug}/master_agreements/${agreement.id}/master_agreement_documents/${documentId}/review`, { review_status: "confirmed" }, { preserveScroll: true })
  }

  function confirmValue(value: ExtractedValue) {
    router.patch(`/${orgSlug}/master_agreements/${agreement.id}/master_agreement_extracted_values/${value.id}`, {
      master_agreement_extracted_value: {
        raw_value: editedValues[value.id] ?? value.raw_value ?? "",
        review_status: "confirmed",
      },
    }, { preserveScroll: true })
  }

  function confirmPriceLine(line: ContractPriceLine) {
    router.patch(`/${orgSlug}/master_agreements/${agreement.id}/master_agreement_product_price_lines/${line.id}`, {
      master_agreement_product_price_line: {
        unit_cost_delivered: editedPrices[line.id] ?? line.unit_cost_delivered ?? "",
        review_status: "confirmed",
      },
    }, { preserveScroll: true })
  }

  return (
    <section className="adg-contract-packet">
      <div className="adg-packet-head">
        <div>
          <div className="adg-flow-label">Contract packet</div>
          <h2>{packet.documents.length || 0} source docs · {confirmedValues} confirmed · {pendingValues} pending</h2>
        </div>
        <form className="adg-packet-upload" onSubmit={upload}>
          <select value={uploadKind} onChange={(event) => setUploadKind(event.target.value)} aria-label="Document kind">
            <option value="agreement">Agreement</option>
            <option value="schedule">Schedule</option>
            <option value="exhibit">Exhibit</option>
            <option value="certificate">Certificate</option>
          </select>
          <input value={uploadTitle} onChange={(event) => setUploadTitle(event.target.value)} placeholder="Document title" />
          <input type="file" accept="application/pdf" onChange={(event) => setUploadFile(event.target.files?.[0] || null)} />
          <button className="adg-btn adg-btn-primary" type="submit" disabled={!uploadFile}><Icon.plus /> Upload</button>
        </form>
      </div>

      <div className="adg-packet-grid">
        <section className="adg-packet-card">
          <h3>Source documents</h3>
          <div className="adg-doc-mini">
            {packet.documents.map((document) => (
              <div className="adg-mini-row" key={document.id}>
                <div className="adg-mini-icon"><Icon.contract /></div>
                <div className="adg-mini-copy">
                  <strong>{document.title}</strong>
                  <small>{document.document_kind} · {document.file_name || "no file"} · {document.docusign.status || document.extraction_status}</small>
                </div>
                <span className={`adg-pill ${pillForExtraction(document.extraction_status)}`}><span className="dot" />{document.extraction_status}</span>
                <button className="adg-icon-btn small" type="button" onClick={() => queueExtraction(document.id)} title="Extract"><Icon.filter /></button>
                <button className="adg-icon-btn small" type="button" onClick={() => confirmDocument(document.id)} title="Confirm"><Icon.check /></button>
              </div>
            ))}
            {packet.documents.length === 0 && <div className="adg-empty-mini">No packet documents uploaded.</div>}
          </div>
        </section>

        <section className="adg-packet-card">
          <h3>Schedules</h3>
          <div className="adg-field-grid">
            {packet.schedules.map((schedule) => (
              <div className="adg-field wide" key={schedule.id}>
                <span>{schedule.review_status}</span>
                <strong>{schedule.product_category || schedule.title}</strong>
                <small>{[schedule.payment_terms, schedule.lead_time_days ? `${schedule.lead_time_days} days` : null, schedule.effective_on, schedule.expires_on].filter(Boolean).join(" · ")}</small>
              </div>
            ))}
            {packet.schedules.length === 0 && <div className="adg-empty-mini">No schedules extracted.</div>}
          </div>
        </section>
      </div>

      <div className="adg-packet-grid">
        <section className="adg-packet-card">
          <h3>Extracted fields</h3>
          <div className="adg-review-list">
            {visibleValues.map((value) => (
              <div className="adg-review-row" key={value.id}>
                <div>
                  <strong>{value.label}</strong>
                  <small>{[value.source_label, value.page_number ? `p.${value.page_number}` : null, confidenceLabel(value.confidence), value.review_status].filter(Boolean).join(" · ")}</small>
                </div>
                <input
                  value={editedValues[value.id] ?? value.raw_value ?? ""}
                  onChange={(event) => setEditedValues({ ...editedValues, [value.id]: event.target.value })}
                />
                <button className="adg-icon-btn small" type="button" onClick={() => confirmValue(value)} title="Confirm value"><Icon.check /></button>
              </div>
            ))}
            {visibleValues.length === 0 && <div className="adg-empty-mini">No extracted fields yet.</div>}
          </div>
        </section>

        <section className="adg-packet-card">
          <h3>Contacts & signers</h3>
          <div className="adg-doc-mini">
            {packet.parties.slice(0, 4).map((party) => (
              <div className="adg-mini-row" key={`party-${party.id}`}>
                <div className="adg-mini-icon"><Icon.user /></div>
                <div className="adg-mini-copy">
                  <strong>{party.legal_name || party.name}</strong>
                  <small>{party.party_role} · {party.state_of_incorporation || party.review_status}</small>
                </div>
              </div>
            ))}
            {packet.signers.slice(0, 4).map((signer) => (
              <div className="adg-mini-row" key={`signer-${signer.id}`}>
                <div className="adg-mini-icon"><Icon.user /></div>
                <div className="adg-mini-copy">
                  <strong>{signer.name}</strong>
                  <small>{[signer.title, signer.company, signer.signed_at?.slice(0, 10)].filter(Boolean).join(" · ")}</small>
                </div>
              </div>
            ))}
            {packet.contacts.slice(0, 5).map((contact) => (
              <div className="adg-mini-row" key={`contact-${contact.id}`}>
                <div className="adg-mini-icon"><Icon.user /></div>
                <div className="adg-mini-copy">
                  <strong>{contact.name || contact.email || contact.contact_type}</strong>
                  <small>{[contact.contact_type, contact.title, contact.phone, contact.email].filter(Boolean).join(" · ")}</small>
                </div>
              </div>
            ))}
            {packet.parties.length + packet.signers.length + packet.contacts.length === 0 && <div className="adg-empty-mini">No contacts extracted.</div>}
          </div>
        </section>
      </div>

      <div className="adg-packet-grid">
        <section className="adg-packet-card">
          <h3>Pricing · {priceLines.length}</h3>
          <div className="adg-price-table">
            {priceLines.slice(0, 12).map((line) => (
              <div className="adg-price-row" key={line.id}>
                <span>{line.participating_company}</span>
                <strong>{line.product_description}</strong>
                <span>{[line.case_pack, line.size, line.uom].filter(Boolean).join(" / ")}</span>
                <input
                  value={editedPrices[line.id] ?? line.unit_cost_delivered ?? ""}
                  onChange={(event) => setEditedPrices({ ...editedPrices, [line.id]: event.target.value })}
                  aria-label={`Delivered unit cost for ${line.product_description}`}
                />
                <button className="adg-icon-btn small" type="button" onClick={() => confirmPriceLine(line)} title="Confirm price"><Icon.check /></button>
              </div>
            ))}
            {priceLines.length === 0 && <div className="adg-empty-mini">No pricing rows extracted.</div>}
          </div>
        </section>

        <section className="adg-packet-card">
          <h3>Locations & clauses</h3>
          <div className="adg-doc-mini">
            {locations.slice(0, 6).map((location) => (
              <div className="adg-mini-row" key={`location-${location.id}`}>
                <div className="adg-mini-icon"><Icon.globe /></div>
                <div className="adg-mini-copy">
                  <strong>{[location.code, location.name].filter(Boolean).join(" · ")}</strong>
                  <small>{[location.address, location.city, location.state_region, location.postal_code].filter(Boolean).join(", ")}</small>
                </div>
              </div>
            ))}
            {packet.clauses.slice(0, 5).map((clause) => (
              <div className="adg-mini-row" key={`clause-${clause.id}`}>
                <div className="adg-mini-icon"><Icon.alert /></div>
                <div className="adg-mini-copy">
                  <strong>{clause.section_number} · {clause.title}</strong>
                  <small>{clause.summary || clause.review_status}</small>
                </div>
              </div>
            ))}
            {locations.length + packet.clauses.length === 0 && <div className="adg-empty-mini">No locations or clauses extracted.</div>}
          </div>
        </section>
      </div>
    </section>
  )
}

function FlowSection({ label, children }: { label: string; children: ReactNode }) {
  return (
    <section className="adg-flow-section">
      <div className="adg-flow-label">{label}</div>
      {children}
    </section>
  )
}

function SelectedPo({ purchaseOrder }: { purchaseOrder: PurchaseOrder }) {
  return (
    <div className="adg-selected-po">
      {purchaseOrder.shipments.map((shipment) => (
        <article className="adg-shipment-flow-row" key={shipment.id}>
          <div>
            <strong>{shipment.shipment_number}</strong>
            <small>{[shipment.pol, shipment.pod].filter(Boolean).join(" -> ") || "Sin ruta"} · ETD {shipment.etd || "sin fecha"}</small>
          </div>
          <span className="adg-pill pill-info"><span className="dot" />{shipment.document_progress.approved}/{shipment.document_progress.total} docs</span>
        </article>
      ))}
    </div>
  )
}

function DocumentPipeline({ documents, selectedDocumentId, onSelectDocument }: { documents: ContractDocument[]; selectedDocumentId: number | null; onSelectDocument: (id: number) => void }) {
  const [hoveredDocumentId, setHoveredDocumentId] = useState<number | null>(null)
  const layout = useMemo(() => computeDocLayout(documents), [documents])
  const activeDocumentId = hoveredDocumentId || selectedDocumentId
  const chain = useMemo(() => computeDirectConnections(activeDocumentId, documents), [activeDocumentId, documents])
  const style = { "--pipeline-width": `${layout.width}px`, "--pipeline-height": `${layout.height}px` } as CSSProperties

  return (
    <div className="adg-doc-pipeline-shell">
      <div className="adg-doc-pipeline" style={style}>
        <svg className="adg-graph-svg" viewBox={`0 0 ${layout.width} ${layout.height}`} preserveAspectRatio="xMinYMin meet">
          {layout.edges.map((edge) => (
            <path
              key={edge.id}
              className={`dep ${activeDocumentId && (edge.fromId === activeDocumentId || edge.toId === activeDocumentId) ? "active" : ""}`}
              d={edge.d}
            />
          ))}
        </svg>

        {layout.stackIndexes.map((stackIndex) => {
          const firstDocument = layout.stacks.get(stackIndex)?.[0]
          const box = firstDocument ? layout.boxes.get(firstDocument.id) : null
          if (!box) return null

          return (
            <div className="adg-stack-label" style={{ left: box.x, top: box.y - 22, width: DOC_W }} key={stackIndex}>
              Tier {stackIndex + 1}{stackIndex > 0 ? " · depends on previous" : " · starting documents"}
            </div>
          )
        })}

        {documents.map((document) => {
          const box = layout.boxes.get(document.id)
          if (!box) return null
          const dim = chain && !chain.has(document.id)
          const selected = selectedDocumentId === document.id

          return (
            <button
              className={`adg-node adg-node-doc sev-${severityForDocument(document)}${selected ? " selected" : ""}${dim ? " dim" : ""}`}
              style={{ left: box.x, top: box.y, width: box.w, height: box.h }}
              type="button"
              onClick={() => onSelectDocument(document.id)}
              onMouseEnter={() => setHoveredDocumentId(document.id)}
              onMouseLeave={() => setHoveredDocumentId(null)}
              onFocus={() => setHoveredDocumentId(document.id)}
              onBlur={() => setHoveredDocumentId(null)}
              key={document.id}
            >
              <div className="adg-nd-top">
                <div className="adg-nd-icon"><Icon.contract /></div>
                <span className={`adg-pill ${pillForDocument(document.status)}`}><span className="dot" />{labelForDocumentStatus(document.status)}</span>
              </div>
              <div className="adg-nd-label">{document.name}</div>
              <div className="adg-nd-foot">
                <span className="adg-nd-ref">{document.grain || document.criticality}</span>
                <span className="adg-nd-ref">{document.assigned_role || "sin responsable"}</span>
              </div>
            </button>
          )
        })}

        <div className="adg-graph-legend">
          <span><i className="dep" />depends on</span>
          <span><i className="route" />selected chain</span>
        </div>
      </div>
    </div>
  )
}

function DocumentDrawer({ document, documents, scopeLabel, agreement, onClose, onApprove, onWaive, onJumpDocument }: {
  document: ContractDocument
  documents: ContractDocument[]
  scopeLabel: string
  agreement: Agreement
  onClose: () => void
  onApprove: (id: number) => void
  onWaive: (id: number) => void
  onJumpDocument: (id: number) => void
}) {
  const dependencies = (document.deps || []).map((id) => documents.find((candidate) => candidate.id === id)).filter(Boolean) as ContractDocument[]
  const dependents = documents.filter((candidate) => (candidate.deps || []).includes(document.id))
  const statusLabel = labelForDocumentStatus(document.status)

  return (
    <aside className="adg-panel" role="dialog" aria-label="Document details">
      <div className="adg-panel-head">
        <div className="adg-ph-icon adg-nd-icon"><Icon.contract /></div>
        <div className="adg-ph-title-wrap">
          <div className="adg-ph-eye">Document · {document.code} · {scopeLabel}</div>
          <div className="adg-ph-title">{document.name}</div>
          <div className="adg-ph-id">{agreement.agreement_number}</div>
        </div>
        <button className="adg-close-btn" type="button" onClick={onClose} title="Close"><Icon.close /></button>
      </div>

      <div className="adg-panel-body">
        <section className="adg-panel-section">
          <div className="adg-panel-status-row">
            <span className={`adg-pill ${pillForDocument(document.status)}`}><span className="dot" />{statusLabel}</span>
            <span className="adg-mini-copy"><small>{document.blocked_by?.length || 0} blockers · {dependents.length} downstream</small></span>
          </div>
          <dl className="adg-kv">
            <dt>Scope</dt><dd>{scopeLabel}</dd>
            <dt>Grain</dt><dd>{document.grain || "—"}</dd>
            <dt>Obligation</dt><dd>{document.obligation || "—"}</dd>
            <dt>Criticality</dt><dd>{document.criticality || "—"}</dd>
            <dt>Owner</dt><dd>{document.assigned_role || "sin responsable"}</dd>
          </dl>
        </section>

        <section className="adg-panel-section">
          <h4>Depends on · {dependencies.length}</h4>
          <MiniDocumentList documents={dependencies} empty="No upstream dependencies" onJump={onJumpDocument} />
        </section>

        <section className="adg-panel-section">
          <h4>Downstream · {dependents.length}</h4>
          <MiniDocumentList documents={dependents} empty="No dependent documents" onJump={onJumpDocument} />
        </section>

        {document.fields.length > 0 && (
          <section className="adg-panel-section">
            <h4>Fields · {document.fields.length}</h4>
            <div className="adg-field-grid">
              {document.fields.map((field) => (
                <div className="adg-field" key={field.id}>
                  <span>{field.source}</span>
                  <strong>{field.raw_value || formatFieldValue(field.value) || field.name}</strong>
                </div>
              ))}
            </div>
          </section>
        )}
      </div>

      <div className="adg-panel-cta">
        <button className="adg-btn adg-btn-outline" type="button" onClick={() => onWaive(document.id)} disabled={document.status === "waived"}>Eximir</button>
        <button className="adg-btn adg-btn-primary" type="button" onClick={() => onApprove(document.id)} disabled={document.status === "approved"}>Aprobar</button>
      </div>
    </aside>
  )
}

function AgreementDrawer({ agreement, purchaseOrders, documents, onClose, onJumpPurchaseOrder }: {
  agreement: Agreement
  purchaseOrders: PurchaseOrder[]
  documents: ContractDocument[]
  onClose: () => void
  onJumpPurchaseOrder: (id: number) => void
}) {
  const approved = documents.filter((document) => document.status === "approved" || document.status === "waived").length

  return (
    <aside className="adg-panel" role="dialog" aria-label="Master Agreement details">
      <div className="adg-panel-head">
        <div className="adg-ph-icon adg-nd-icon"><Icon.contract /></div>
        <div className="adg-ph-title-wrap">
          <div className="adg-ph-eye">Contract · Master Agreement</div>
          <div className="adg-ph-title">{agreement.name}</div>
          <div className="adg-ph-id">{agreement.agreement_number}</div>
        </div>
        <button className="adg-close-btn" type="button" onClick={onClose} title="Close"><Icon.close /></button>
      </div>

      <div className="adg-panel-body">
        <section className="adg-panel-section">
          <dl className="adg-kv">
            <dt>Customer</dt><dd>{agreement.trading_partner.legal_name || agreement.trading_partner.name}</dd>
            <dt>Country</dt><dd>{agreement.trading_partner.country || "—"}</dd>
            <dt>Incoterm</dt><dd>{agreement.incoterm || "—"}</dd>
            <dt>Payment</dt><dd>{agreement.payment_terms || "—"}</dd>
            <dt>Currency</dt><dd>{agreement.currency || "—"}</dd>
            <dt>Expires</dt><dd>{agreement.expires_on || "—"}</dd>
          </dl>
        </section>

        <section className="adg-panel-section">
          <h4>Contract documents · {documents.length}</h4>
          <div className="adg-panel-status-row">
            <span className="adg-pill pill-info"><span className="dot" />{approved}/{documents.length} approved</span>
          </div>
          <MiniDocumentList documents={documents} empty="No contract-level documents" onJump={() => undefined} />
        </section>

        <section className="adg-panel-section">
          <h4>Purchase orders · {purchaseOrders.length}</h4>
          <div className="adg-doc-mini">
            {purchaseOrders.map((purchaseOrder) => (
              <button className="adg-mini-row" type="button" onClick={() => onJumpPurchaseOrder(purchaseOrder.id)} key={purchaseOrder.id}>
                <div className="adg-mini-icon"><Icon.po /></div>
                <div className="adg-mini-copy">
                  <strong>{purchaseOrder.po_number}</strong>
                  <small>{purchaseOrder.destination_country || "Destino pendiente"} · {purchaseOrder.lines_count} items</small>
                </div>
                <span className={`adg-pill ${pillForPurchaseOrder(purchaseOrder.status)}`}><span className="dot" />{labelForPurchaseOrderStatus(purchaseOrder.status)}</span>
              </button>
            ))}
          </div>
        </section>
      </div>
    </aside>
  )
}

function PurchaseOrderDrawer({ agreement, purchaseOrder, onClose }: { agreement: Agreement; purchaseOrder: PurchaseOrder; onClose: () => void }) {
  const documents = uniqueDocuments(purchaseOrder.shipments.flatMap((shipment) => shipment.documents))
  const approved = documents.filter((document) => document.status === "approved" || document.status === "waived").length

  return (
    <aside className="adg-panel" role="dialog" aria-label="Purchase Order details">
      <div className="adg-panel-head">
        <div className="adg-ph-icon adg-nd-icon"><Icon.po /></div>
        <div className="adg-ph-title-wrap">
          <div className="adg-ph-eye">Purchase Order · under {agreement.agreement_number}</div>
          <div className="adg-ph-title">{purchaseOrder.po_number}</div>
          <div className="adg-ph-id">{purchaseOrder.destination_country || "Destino pendiente"}</div>
        </div>
        <button className="adg-close-btn" type="button" onClick={onClose} title="Close"><Icon.close /></button>
      </div>

      <div className="adg-panel-body">
        <section className="adg-panel-section">
          <dl className="adg-kv">
            <dt>Status</dt><dd>{labelForPurchaseOrderStatus(purchaseOrder.status)}</dd>
            <dt>Destination</dt><dd>{purchaseOrder.destination_country || "—"}</dd>
            <dt>Incoterm</dt><dd>{purchaseOrder.incoterm || agreement.incoterm || "—"}</dd>
            <dt>Value</dt><dd>{formatMoney(purchaseOrder.total_amount, purchaseOrder.currency || agreement.currency)}</dd>
            <dt>Required ship</dt><dd>{purchaseOrder.required_ship_on || "—"}</dd>
            <dt>Issued</dt><dd>{purchaseOrder.issued_on || "—"}</dd>
          </dl>
        </section>

        <section className="adg-panel-section">
          <h4>Shipments · {purchaseOrder.shipments.length}</h4>
          <div className="adg-doc-mini">
            {purchaseOrder.shipments.map((shipment) => (
              <div className="adg-mini-row" key={shipment.id}>
                <div className="adg-mini-icon"><Icon.container /></div>
                <div className="adg-mini-copy">
                  <strong>{shipment.shipment_number}</strong>
                  <small>{[shipment.pol, shipment.pod].filter(Boolean).join(" -> ") || "Sin ruta"} · ETD {shipment.etd || "sin fecha"}</small>
                </div>
                <span className="adg-pill pill-info"><span className="dot" />{shipment.document_progress.approved}/{shipment.document_progress.total}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="adg-panel-section">
          <h4>Workflow documents · {documents.length}</h4>
          <div className="adg-panel-status-row">
            <span className="adg-pill pill-info"><span className="dot" />{approved}/{documents.length} approved</span>
          </div>
          <MiniDocumentList documents={documents.slice(0, 8)} empty="No workflow documents" onJump={() => undefined} />
        </section>
      </div>
    </aside>
  )
}

function MiniDocumentList({ documents, empty, onJump }: { documents: ContractDocument[]; empty: string; onJump: (id: number) => void }) {
  if (documents.length === 0) return <div className="adg-empty-mini">{empty}</div>

  return (
    <div className="adg-doc-mini">
      {documents.map((document) => (
        <button className="adg-mini-row" type="button" onClick={() => onJump(document.id)} key={document.id}>
          <div className="adg-mini-icon"><Icon.contract /></div>
          <div className="adg-mini-copy">
            <strong>{document.name}</strong>
            <small>{document.code} · {document.grain || document.criticality}</small>
          </div>
          <span className={`adg-pill ${pillForDocument(document.status)}`}><span className="dot" />{labelForDocumentStatus(document.status)}</span>
        </button>
      ))}
    </div>
  )
}

function computeDocLayout(documents: ContractDocument[]): DocLayout {
  const byId = new Map(documents.map((document) => [document.id, document]))
  const stackOf = new Map<number, number>()

  function stackFor(documentId: number, seen = new Set<number>()): number {
    if (stackOf.has(documentId)) return stackOf.get(documentId) || 0
    if (seen.has(documentId)) return 0

    seen.add(documentId)
    const document = byId.get(documentId)
    const internalDeps = layoutDependencies(document, byId)
    if (internalDeps.length === 0) {
      stackOf.set(documentId, 0)
      return 0
    }

    const stackIndex = Math.max(...internalDeps.map((id) => stackFor(id, seen))) + 1
    stackOf.set(documentId, stackIndex)
    return stackIndex
  }

  documents.forEach((document) => stackFor(document.id))

  const stacks = new Map<number, ContractDocument[]>()
  documents.forEach((document) => {
    const stackIndex = stackOf.get(document.id) || 0
    stacks.set(stackIndex, [...(stacks.get(stackIndex) || []), document])
  })

  const stackIndexes = [...stacks.keys()].sort((a, b) => a - b)
  const rowOf = new Map<number, number>()
  stackIndexes.forEach((stackIndex) => {
    const stackDocs = stacks.get(stackIndex) || []
    if (stackIndex > 0) {
      stackDocs.sort((a, b) => averageDepRow(a, rowOf, byId) - averageDepRow(b, rowOf, byId) || a.name.localeCompare(b.name))
    } else {
      stackDocs.sort((a, b) => documentRootWeight(a) - documentRootWeight(b) || a.name.localeCompare(b.name))
    }
    stackDocs.forEach((document, index) => rowOf.set(document.id, index))
  })

  const bands = new Map<number, number>()
  stackIndexes.forEach((stackIndex) => {
    const band = Math.floor(stackIndex / DOC_VISIBLE_COLUMNS)
    const stackRows = stacks.get(stackIndex)?.length || 1
    bands.set(band, Math.max(bands.get(band) || 1, stackRows))
  })

  const bandStarts = new Map<number, number>()
  let nextBandY = DOC_TOP
  ;[...bands.keys()].sort((a, b) => a - b).forEach((band) => {
    bandStarts.set(band, nextBandY)
    nextBandY += (bands.get(band) || 1) * (DOC_H + DOC_ROW_GAP) + 78
  })

  const boxes = new Map<number, Box>()
  let height = DOC_TOP + DOC_H
  stackIndexes.forEach((stackIndex) => {
    const stackDocs = stacks.get(stackIndex) || []
    const band = Math.floor(stackIndex / DOC_VISIBLE_COLUMNS)
    const column = stackIndex % DOC_VISIBLE_COLUMNS
    stackDocs.forEach((document, rowIndex) => {
      const box = {
        x: DOC_LEFT + column * (DOC_W + DOC_COL_GAP),
        y: (bandStarts.get(band) || DOC_TOP) + rowIndex * (DOC_H + DOC_ROW_GAP),
        w: DOC_W,
        h: DOC_H,
      }
      boxes.set(document.id, box)
      height = Math.max(height, box.y + box.h + 48)
    })
  })

  const edges = documents.flatMap((document) => {
    const to = boxes.get(document.id)
    if (!to) return []

    return layoutDependencies(document, byId).flatMap((dependencyId) => {
      const from = boxes.get(dependencyId)
      if (!from) return []

      return [{
        id: `dep-${dependencyId}-${document.id}`,
        fromId: dependencyId,
        toId: document.id,
        d: dependencyPath(rightCenter(from), leftCenter(to)),
      }]
    })
  })

  return {
    boxes,
    stacks,
    stackIndexes,
    edges,
    width: DOC_LEFT * 2 + DOC_VISIBLE_COLUMNS * DOC_W + (DOC_VISIBLE_COLUMNS - 1) * DOC_COL_GAP,
    height: Math.max(240, height),
  }
}

function averageDepRow(document: ContractDocument, rowOf: Map<number, number>, byId: Map<number, ContractDocument>) {
  const rows = layoutDependencies(document, byId).filter((id) => rowOf.has(id)).map((id) => rowOf.get(id) || 0)
  if (rows.length === 0) return 999
  return rows.reduce((sum, row) => sum + row, 0) / rows.length
}

function layoutDependencies(document: ContractDocument | undefined, byId: Map<number, ContractDocument>) {
  if (!document) return []

  const dependencies = (document.deps || []).filter((dependencyId) => {
    const dependency = byId.get(dependencyId)
    if (!dependency) return false

    return !(document.code === "purchase_order" && dependency.code === "master_agreement")
  })

  if (dependencies.length > 0) return dependencies
  if (document.code === "master_agreement" || document.code === "purchase_order") return dependencies

  const purchaseOrder = [...byId.values()].find((candidate) => candidate.code === "purchase_order")
  return purchaseOrder ? [purchaseOrder.id] : dependencies
}

function documentRootWeight(document: ContractDocument) {
  if (document.code === "purchase_order") return 0
  if (document.code === "master_agreement") return 1
  return 2
}

function computeDirectConnections(selectedDocumentId: number | null, documents: ContractDocument[]) {
  if (!selectedDocumentId) return null

  const byId = new Map(documents.map((document) => [document.id, document]))
  if (!byId.has(selectedDocumentId)) return null

  const selected = new Set<number>([selectedDocumentId])
  ;(byId.get(selectedDocumentId)?.deps || []).forEach((dependencyId) => {
    if (byId.has(dependencyId)) selected.add(dependencyId)
  })
  documents.forEach((document) => {
    if ((document.deps || []).includes(selectedDocumentId)) selected.add(document.id)
  })

  return selected
}

function dependencyPath(from: Point, to: Point) {
  if (to.x > from.x) {
    const railX = from.x + Math.max(32, (to.x - from.x) / 2)
    return `M ${from.x} ${from.y} C ${railX} ${from.y}, ${railX} ${to.y}, ${to.x} ${to.y}`
  }

  const railX = from.x + 58
  const railY = from.y + Math.max(46, (to.y - from.y) / 2)
  return `M ${from.x} ${from.y} C ${railX} ${from.y}, ${railX} ${railY}, ${railX} ${railY} C ${railX} ${to.y}, ${to.x - 48} ${to.y}, ${to.x} ${to.y}`
}

function rightCenter(box: Box) {
  return { x: box.x + box.w, y: box.y + box.h / 2 }
}

function leftCenter(box: Box) {
  return { x: box.x, y: box.y + box.h / 2 }
}

function documentsForLens(lens: Lens | null, selectedPo: PurchaseOrder | undefined, selectedItem: Item | undefined, contractDocuments: ContractDocument[], marketDocuments: ContractDocument[]) {
  if (lens === "pos" && selectedPo) return uniqueDocuments(selectedPo.shipments.flatMap((shipment) => shipment.documents))
  if (lens === "items" && selectedItem) return selectedItem.documents
  if (lens === "customer") return contractDocuments
  if (lens === "market") return marketDocuments
  return []
}

function countForLens(lens: Lens, purchaseOrders: PurchaseOrder[], items: Item[], contractDocuments: ContractDocument[], marketDocuments: ContractDocument[]) {
  if (lens === "pos") return purchaseOrders.length
  if (lens === "items") return items.length
  if (lens === "customer") return contractDocuments.length > 0 ? 1 : "—"
  return destinationsFor(purchaseOrders).length > 0 || marketDocuments.length > 0 ? 1 : "—"
}

function scopeLabelFor(lens: Lens | null, selectedPo: PurchaseOrder | undefined, selectedItem: Item | undefined, agreement: Agreement, purchaseOrders: PurchaseOrder[]) {
  if (lens === "pos") return selectedPo?.po_number || "Purchase Orders"
  if (lens === "items") return selectedItem?.label || "Items"
  if (lens === "customer") return agreement.trading_partner.name
  if (lens === "market") return destinationsFor(purchaseOrders).join(", ") || "Market"
  return agreement.agreement_number
}

function destinationsFor(purchaseOrders: PurchaseOrder[]) {
  return [...new Set(purchaseOrders.map((purchaseOrder) => purchaseOrder.destination_country).filter(Boolean) as string[])]
}

function uniqueDocuments(documents: ContractDocument[]) {
  const seen = new Set<number>()
  return documents.filter((document) => {
    if (seen.has(document.id)) return false
    seen.add(document.id)
    return true
  })
}

function severityForAgreement(agreement: Agreement) {
  if (agreement.status === "terminated") return "crit"
  if (agreement.status === "expired") return "watch"
  if (agreement.contract_document_progress.total > agreement.contract_document_progress.approved) return "watch"
  return "ok"
}

function severityForPurchaseOrder(purchaseOrder: PurchaseOrder) {
  if (purchaseOrder.status === "cancelled") return "crit"
  if (purchaseOrder.status === "draft" || purchaseOrder.shipments.length === 0) return "watch"
  if (purchaseOrder.status === "completed") return "ok"
  return "info"
}

function severityForDocument(document: ContractDocument) {
  if (document.status === "approved" || document.status === "waived") return "ok"
  if (document.status === "blocked" || document.status === "rejected" || document.criticality === "critico") return "crit"
  if (document.criticality === "alto" || document.criticality === "medio") return "watch"
  return "info"
}

function pillForPurchaseOrder(status: string) {
  if (status === "completed") return "pill-ok"
  if (status === "cancelled") return "pill-crit"
  if (status === "draft") return "pill-watch"
  return "pill-info"
}

function pillForDocument(status: string) {
  if (status === "approved" || status === "waived") return "pill-ok"
  if (status === "blocked" || status === "rejected") return "pill-crit"
  if (status === "pending" || status === "in_review") return "pill-watch"
  return "pill-neutral"
}

function pillForExtraction(status: string) {
  if (status === "succeeded" || status === "confirmed") return "pill-ok"
  if (status === "failed") return "pill-crit"
  if (status === "processing" || status === "pending" || status === "needs_review") return "pill-watch"
  return "pill-neutral"
}

function confidenceLabel(confidence?: number | null) {
  if (confidence === null || confidence === undefined) return ""
  return `${Math.round(confidence * 100)}% confidence`
}

function labelForDocumentStatus(status: string) {
  const labels: Record<string, string> = {
    not_started: "Sin iniciar",
    blocked: "Bloqueado",
    pending: "Pendiente",
    in_review: "Revision",
    approved: "Aprobado",
    rejected: "Rechazado",
    waived: "Eximido",
  }
  return labels[status] || status
}

function labelForPurchaseOrderStatus(status: string) {
  const labels: Record<string, string> = {
    draft: "Draft",
    received: "Ready",
    validated: "Ready",
    in_production: "Production",
    shipping: "Shipping",
    completed: "Closed",
    cancelled: "Cancelled",
  }
  return labels[status] || status
}

function formatMoney(value?: string | number | null, currency?: string | null) {
  if (value === null || value === undefined || value === "") return `${currency || "USD"} —`
  const amount = Number(value)
  if (Number.isNaN(amount)) return String(value)
  if (amount <= 0) return `${currency || "USD"} —`
  if (amount >= 1_000_000) return `${currency || "USD"} ${(amount / 1_000_000).toFixed(1)}M`
  return `${currency || "USD"} ${(amount / 1_000).toFixed(0)}K`
}

function formatFieldValue(value: unknown) {
  if (value === null || value === undefined) return ""
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") return String(value)
  return JSON.stringify(value)
}

function shortDate(date?: string | null) {
  if (!date) return ""
  return date.slice(5)
}

function flagForCountry(country?: string | null) {
  const flags: Record<string, string> = {
    Chile: "🇨🇱",
    China: "🇨🇳",
    France: "🇫🇷",
    USA: "🇺🇸",
    "United States": "🇺🇸",
    Mexico: "🇲🇽",
    Brazil: "🇧🇷",
  }

  return flags[country || ""] || ""
}
