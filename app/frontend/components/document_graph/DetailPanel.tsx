import { DocIcon, Icon } from "./icons"
import { documentStatusMeta } from "./GraphNodes"
import type { ExternalSource, GraphDocument, GraphSelection, ShipmentGraph } from "./types"

interface DetailPanelProps {
  graph: ShipmentGraph
  selection: GraphSelection | null
  onClose: () => void
  onSelect: (selection: GraphSelection) => void
  onApprove: (documentId: number) => void
  onWaive: (documentId: number) => void
}

export function DetailPanel({ graph, selection, onClose, onSelect, onApprove, onWaive }: DetailPanelProps) {
  if (!selection) return null

  if (selection.kind === "doc") {
    const document = graph.documents.find((doc) => doc.graph_id === selection.id)
    if (!document) return null
    return <DocumentPanel graph={graph} document={document} onClose={onClose} onSelect={onSelect} onApprove={onApprove} onWaive={onWaive} />
  }

  if (selection.kind === "ext") {
    const source = graph.external_sources.find((external) => external.id === selection.id)
    if (!source) return null
    return <ExternalPanel graph={graph} source={source} onClose={onClose} onSelect={onSelect} />
  }

  return <ContextPanel graph={graph} selection={selection} onClose={onClose} onSelect={onSelect} />
}

function PanelShell({ children }: { children: React.ReactNode }) {
  return (
    <aside className="adg-panel" aria-label="Detalle">
      {children}
    </aside>
  )
}

function PanelHead({ icon, eyebrow, title, id, onClose }: { icon: React.ReactNode; eyebrow: string; title: string; id?: string; onClose: () => void }) {
  return (
    <div className="adg-panel-head">
      <div className="adg-ph-icon">{icon}</div>
      <div className="adg-ph-title-wrap">
        <div className="adg-ph-eye">{eyebrow}</div>
        <div className="adg-ph-title">{title}</div>
        {id && <div className="adg-ph-id">{id}</div>}
      </div>
      <button className="adg-close-btn" onClick={onClose} title="Cerrar" type="button"><Icon.close /></button>
    </div>
  )
}

function ContextPanel({ graph, selection, onClose, onSelect }: { graph: ShipmentGraph; selection: GraphSelection; onClose: () => void; onSelect: (selection: GraphSelection) => void }) {
  const data = contextData(graph, selection)
  const scopedDocs = selection.kind === "category" ? graph.documents.filter((doc) => doc.scope === selection.id) : graph.documents

  return (
    <PanelShell>
      <PanelHead icon={data.icon} eyebrow={data.eyebrow} title={data.title} id={data.id} onClose={onClose} />
      <div className="adg-panel-body">
        <section className="adg-panel-section">
          <dl className="adg-kv">
            {data.rows.map((row) => (
              <FragmentRow key={row.label} label={row.label} value={row.value} />
            ))}
          </dl>
        </section>
        <section className="adg-panel-section">
          <h4>Documentos · {scopedDocs.length}</h4>
          <MiniDocumentList documents={scopedDocs.slice(0, 8)} onSelect={onSelect} />
        </section>
      </div>
    </PanelShell>
  )
}

function DocumentPanel({
  graph,
  document,
  onClose,
  onSelect,
  onApprove,
  onWaive,
}: {
  graph: ShipmentGraph
  document: GraphDocument
  onClose: () => void
  onSelect: (selection: GraphSelection) => void
  onApprove: (documentId: number) => void
  onWaive: (documentId: number) => void
}) {
  const status = documentStatusMeta(document.status)
  const deps = document.deps.map((dep) => graph.documents.find((doc) => doc.graph_id === dep)).filter(Boolean) as GraphDocument[]
  const provider = document.ext ? graph.external_sources.find((external) => external.id === document.ext) : undefined
  const checks = graph.source_of_truth_checks.filter((check) => check.authoritative_document === document.label || check.target_document === document.label)

  return (
    <PanelShell>
      <PanelHead icon={<DocIcon type={document.type} />} eyebrow={`Documento · ${document.short}`} title={document.label} id={document.grain} onClose={onClose} />
      <div className="adg-panel-body">
        <section className="adg-panel-section">
          <div className="adg-panel-status-row">
            <span className={`adg-pill ${status.className}`}><span className="dot" />{status.label}</span>
            <span className="adg-mono">Criticidad {document.criticality}</span>
          </div>
          <dl className="adg-kv">
            <FragmentRow label="Responsable" value={document.assigned_role || "Sin asignar"} />
            <FragmentRow label="Obligacion" value={document.obligation} />
            <FragmentRow label="Emitido por" value={document.issued_by || "Interno"} />
            <FragmentRow label="Vence" value={document.due_on || "Sin fecha"} />
          </dl>
          {document.blocked_by.length > 0 && (
            <div className="adg-alert-line">
              <Icon.alert />
              <span>Bloqueado por {document.blocked_by.map((blocker) => blocker.label).join(", ")}</span>
            </div>
          )}
        </section>

        {deps.length > 0 && (
          <section className="adg-panel-section">
            <h4>Depende de · {deps.length}</h4>
            <MiniDocumentList documents={deps} onSelect={onSelect} />
          </section>
        )}

        {provider && (
          <section className="adg-panel-section">
            <h4>Proveedor externo</h4>
            <button className="adg-mini-row dashed" type="button" onClick={() => onSelect({ kind: "ext", id: provider.id })}>
              <span className="adg-mini-icon"><Icon.external /></span>
              <span className="adg-mini-copy">
                <strong>{provider.name}</strong>
                <small>{provider.kind} · {provider.sla}</small>
              </span>
              <Icon.chevron />
            </button>
          </section>
        )}

        {document.fields.length > 0 && (
          <section className="adg-panel-section">
            <h4>Campos · {document.fields.length}</h4>
            <div className="adg-field-grid">
              {document.fields.slice(0, 8).map((field) => (
                <div className="adg-field" key={field.id}>
                  <span>{field.name}</span>
                  <strong>{field.raw_value || formatValue(field.value) || "Sin valor"}</strong>
                </div>
              ))}
            </div>
          </section>
        )}

        {checks.length > 0 && (
          <section className="adg-panel-section">
            <h4>Fuente de verdad · {checks.length}</h4>
            <div className="adg-activity">
              {checks.map((check) => (
                <div className="adg-a-row" key={check.id}>
                  <span className={`adg-a-dot ${check.status === "matched" ? "ok" : "watch"}`} />
                  <span className="adg-a-text">{check.field_name}: <strong>{check.status === "matched" ? "cuadra" : "diferencia"}</strong></span>
                  <span className="adg-a-time">{check.failure_action}</span>
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
    </PanelShell>
  )
}

function ExternalPanel({ graph, source, onClose, onSelect }: { graph: ShipmentGraph; source: ExternalSource; onClose: () => void; onSelect: (selection: GraphSelection) => void }) {
  const documents = graph.documents.filter((doc) => doc.ext === source.id)

  return (
    <PanelShell>
      <PanelHead icon={<Icon.external />} eyebrow="Proveedor externo" title={source.name} id={source.code} onClose={onClose} />
      <div className="adg-panel-body">
        <section className="adg-panel-section">
          <dl className="adg-kv">
            <FragmentRow label="Tipo" value={source.kind} />
            <FragmentRow label="SLA" value={source.sla} />
            <FragmentRow label="Docs alimentados" value={String(documents.length)} />
            <FragmentRow label="Adapter" value="Derivado de roles y fuentes" />
          </dl>
        </section>
        <section className="adg-panel-section">
          <h4>Documentos alimentados · {documents.length}</h4>
          <MiniDocumentList documents={documents} onSelect={onSelect} />
        </section>
      </div>
    </PanelShell>
  )
}

function MiniDocumentList({ documents, onSelect }: { documents: GraphDocument[]; onSelect: (selection: GraphSelection) => void }) {
  return (
    <div className="adg-doc-mini">
      {documents.map((document) => {
        const status = documentStatusMeta(document.status)
        return (
          <button className="adg-mini-row" key={document.graph_id} type="button" onClick={() => onSelect({ kind: "doc", id: document.graph_id })}>
            <span className="adg-mini-icon"><DocIcon type={document.type} /></span>
            <span className="adg-mini-copy">
              <strong>{document.label}</strong>
              <small>{document.short} · {document.grain}</small>
            </span>
            <span className={`adg-pill ${status.className}`}><span className="dot" />{status.label}</span>
          </button>
        )
      })}
      {documents.length === 0 && <div className="adg-empty-mini">Sin documentos en este lente.</div>}
    </div>
  )
}

function FragmentRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <>
      <dt>{label}</dt>
      <dd>{value || "-"}</dd>
    </>
  )
}

function contextData(graph: ShipmentGraph, selection: GraphSelection) {
  if (selection.kind === "purchase_order") {
    return {
      icon: <Icon.po />,
      eyebrow: "Orden de compra",
      title: graph.purchase_order.label,
      id: graph.root.label,
      rows: [
        { label: "Cliente", value: graph.purchase_order.buyer },
        { label: "Estado", value: graph.purchase_order.status },
        { label: "Incoterm", value: graph.purchase_order.incoterm },
        { label: "Monto", value: formatMoney(graph.purchase_order.total_amount, graph.purchase_order.currency) },
      ],
    }
  }
  if (selection.kind === "customer") {
    return {
      icon: <Icon.user />,
      eyebrow: "Cliente",
      title: graph.customer.label,
      id: graph.customer.agreement_number || undefined,
      rows: [
        { label: "Legal", value: graph.customer.legal_name },
        { label: "Pais", value: graph.customer.country },
        { label: "Acuerdo", value: graph.customer.master_agreement },
        { label: "Terminos", value: graph.customer.payment_terms },
      ],
    }
  }
  if (selection.kind === "market") {
    return {
      icon: <Icon.globe />,
      eyebrow: "Mercado",
      title: graph.market.label,
      id: graph.market.region,
      rows: [
        { label: "Autoridad", value: graph.market.authority },
        { label: "Destino", value: graph.root.destination_country },
        { label: "Ruta", value: graph.root.route },
        { label: "Validaciones", value: String(graph.source_of_truth_checks.length) },
      ],
    }
  }
  if (selection.kind === "item") {
    const item = graph.items.find((candidate) => candidate.id === selection.id)
    return {
      icon: <Icon.apple />,
      eyebrow: "Item",
      title: item?.label || "Item",
      id: item?.sku,
      rows: [
        { label: "Cantidad", value: [item?.quantity, item?.unit].filter(Boolean).join(" ") },
        { label: "Packaging", value: item?.packaging },
        { label: "HS", value: item?.hs_code },
        { label: "Docs", value: String(item?.documents_count || 0) },
      ],
    }
  }
  if (selection.kind === "category") {
    const category = graph.categories.find((candidate) => candidate.id === selection.id)
    return {
      icon: category?.icon === "apple" ? <Icon.apple /> : category?.icon === "user" ? <Icon.user /> : category?.icon === "globe" ? <Icon.globe /> : <Icon.po />,
      eyebrow: "Lente",
      title: category?.label || "Documentos",
      id: graph.root.label,
      rows: [
        { label: "Documentos", value: String(graph.documents.filter((doc) => doc.scope === selection.id).length) },
        { label: "Descripcion", value: category?.blurb },
        { label: "Estado", value: category?.enabled ? "Activo" : "Sin datos" },
      ],
    }
  }
  return {
    icon: <Icon.contract />,
    eyebrow: "Embarque",
    title: graph.root.label,
    id: graph.root.po_number,
    rows: [
      { label: "Cliente", value: graph.root.buyer },
      { label: "Ruta", value: graph.root.route },
      { label: "ETD", value: graph.root.etd },
      { label: "Booking", value: graph.root.booking_number },
    ],
  }
}

function formatValue(value: unknown) {
  if (value === null || value === undefined) return ""
  if (typeof value === "string") return value
  if (typeof value === "number" || typeof value === "boolean") return String(value)
  return JSON.stringify(value)
}

function formatMoney(value?: string | number | null, currency?: string | null) {
  if (value === null || value === undefined || value === "") return undefined
  const amount = Number(value)
  if (Number.isNaN(amount)) return String(value)
  return new Intl.NumberFormat("es-CL", { style: "currency", currency: currency || "USD", maximumFractionDigits: 0 }).format(amount)
}
