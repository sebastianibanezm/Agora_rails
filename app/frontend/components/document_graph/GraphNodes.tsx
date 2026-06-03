import { DocIcon, Icon } from "./icons"
import type {
  ExternalSource,
  GraphBox,
  GraphCategory,
  GraphCustomer,
  GraphDocument,
  GraphItem,
  GraphMarket,
  GraphPurchaseOrder,
  GraphRoot,
} from "./types"

export function RootNode({ root, box, active, onClick }: { root: GraphRoot; box: GraphBox; active: boolean; onClick: () => void }) {
  return (
    <button className={`adg-node adg-node-contract${active ? " active" : ""}`} style={boxStyle(box)} onClick={onClick} type="button">
      <div className="adg-nc-top">
        <div className="adg-nc-icon"><Icon.contract /></div>
        <div>
          <div className="adg-nc-id">{root.label}</div>
          <div className="adg-nc-name">{root.buyer}</div>
        </div>
      </div>
      <div className="adg-nc-meta">
        <span>PO <strong>{root.po_number}</strong></span>
        <span>{root.route || "Ruta pendiente"}</span>
        <span>ETD <strong>{root.etd || "sin fecha"}</strong></span>
      </div>
    </button>
  )
}

export function CategoryNode({
  category,
  box,
  active,
  dimmed,
  onClick,
}: {
  category: GraphCategory
  box: GraphBox
  active: boolean
  dimmed: boolean
  onClick: () => void
}) {
  const CatIcon = Icon[category.icon as keyof typeof Icon] || Icon.contract
  return (
    <button
      className={`adg-node adg-node-cat cat-${category.id}${active ? " active" : ""}${dimmed ? " dim" : ""}${category.enabled ? "" : " disabled"}`}
      style={boxStyle(box)}
      onClick={category.enabled ? onClick : undefined}
      type="button"
      disabled={!category.enabled}
    >
      <div className="adg-cat-top">
        <div className="adg-cat-icon"><CatIcon /></div>
        <div className="adg-cat-count">{category.enabled ? category.count : "-"}</div>
      </div>
      <div className="adg-cat-label">{category.label}</div>
      <div className="adg-cat-blurb">{category.enabled ? category.blurb : "Sin datos expuestos"}</div>
    </button>
  )
}

export function PurchaseOrderNode({
  purchaseOrder,
  box,
  active,
  onClick,
}: {
  purchaseOrder: GraphPurchaseOrder
  box: GraphBox
  active: boolean
  onClick: () => void
}) {
  return (
    <button className={`adg-node adg-node-po sev-info${active ? " active" : ""}`} style={boxStyle(box)} onClick={onClick} type="button">
      <div className="adg-np-top">
        <span className="adg-np-id">{purchaseOrder.label}</span>
        <span className="adg-pill pill-info"><span className="dot" />{labelForPurchaseOrderStatus(purchaseOrder.status)}</span>
      </div>
      <div className="adg-np-route">{purchaseOrder.destination_country || "Destino pendiente"}</div>
      <div className="adg-np-carrier">
        <span>{purchaseOrder.buyer}</span>
        <span className="containers">{purchaseOrder.incoterm || "Incoterm"}</span>
      </div>
      <div className="adg-np-foot">
        <span>{purchaseOrder.documents_count} docs PO</span>
        <span className="eta">{purchaseOrder.required_ship_on || purchaseOrder.issued_on || "sin fecha"}</span>
      </div>
    </button>
  )
}

export function ItemNode({ item, box, active, dimmed, onClick }: { item: GraphItem; box: GraphBox; active: boolean; dimmed: boolean; onClick: () => void }) {
  return (
    <button className={`adg-node adg-node-item sev-ok${active ? " active" : ""}${dimmed ? " dim" : ""}`} style={boxStyle(box)} onClick={onClick} type="button">
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
  )
}

export function CustomerInfoNode({ customer, box, onClick }: { customer: GraphCustomer; box: GraphBox; onClick: () => void }) {
  return (
    <button className="adg-node adg-node-info adg-node-info-cust" style={boxStyle(box)} onClick={onClick} type="button">
      <div className="adg-info-top">
        <div className="adg-info-avatar"><Icon.user /></div>
        <div>
          <div className="adg-info-eye">Cliente · {customer.partner_type || "buyer"}</div>
          <div className="adg-info-name">{customer.label}</div>
          <div className="adg-info-id">{customer.legal_name || customer.country || "Contraparte comercial"}</div>
        </div>
      </div>
      <div className="adg-info-desc">
        Acuerdo maestro {customer.agreement_number || "sin numero"} asociado a esta PO. Terminos: {customer.payment_terms || "por confirmar"}.
      </div>
      <div className="adg-info-kv">
        <span><span className="k">Pais</span><span className="v">{customer.country || "-"}</span></span>
        <span><span className="k">Tax ID</span><span className="v">{customer.tax_identifier || "-"}</span></span>
        <span><span className="k">Docs</span><span className="v">{customer.documents_count}</span></span>
      </div>
    </button>
  )
}

export function MarketInfoNode({ market, box, onClick }: { market: GraphMarket; box: GraphBox; onClick: () => void }) {
  return (
    <button className="adg-node adg-node-info adg-node-info-mkt" style={boxStyle(box)} onClick={onClick} type="button">
      <div className="adg-info-top">
        <div className="adg-info-avatar"><Icon.globe /></div>
        <div>
          <div className="adg-info-eye">Mercado destino · {market.region}</div>
          <div className="adg-info-name">{market.label}</div>
          <div className="adg-info-id">{market.authority}</div>
        </div>
      </div>
      <div className="adg-info-desc">
        Documentos regulatorios, de embarque y cuadraturas de fuente de verdad que condicionan la liberacion del flujo.
      </div>
      <div className="adg-info-kv">
        <span><span className="k">Destino</span><span className="v">{market.label}</span></span>
        <span><span className="k">Docs</span><span className="v">{market.documents_count}</span></span>
        <span><span className="k">Control</span><span className="v">SOT</span></span>
      </div>
    </button>
  )
}

export function DocNode({
  doc,
  box,
  dimmed,
  active,
  selected,
  onClick,
}: {
  doc: GraphDocument
  box: GraphBox
  dimmed: boolean
  active: boolean
  selected: boolean
  onClick: () => void
}) {
  const status = documentStatusMeta(doc.status)
  return (
    <button
      className={`adg-node adg-node-doc sev-${doc.severity}${dimmed ? " dim" : ""}${active ? " active" : ""}${selected ? " selected" : ""}`}
      style={boxStyle(box)}
      onClick={onClick}
      type="button"
    >
      <div className="adg-nd-top">
        <div className="adg-nd-icon"><DocIcon type={doc.type} /></div>
        <div className="adg-nd-short">{doc.short}</div>
      </div>
      <div className="adg-nd-label">{doc.label}</div>
      <div className="adg-nd-foot">
        <span className="adg-nd-ref">{doc.grain}</span>
        <span className={`adg-pill ${status.className}`}><span className="dot" />{status.label}</span>
      </div>
    </button>
  )
}

export function ExternalNode({
  source,
  box,
  dimmed,
  active,
  selected,
  onClick,
}: {
  source: ExternalSource
  box: GraphBox
  dimmed: boolean
  active: boolean
  selected: boolean
  onClick: () => void
}) {
  return (
    <button
      className={`adg-node adg-node-ext${dimmed ? " dim" : ""}${active ? " active" : ""}${selected ? " selected" : ""}`}
      style={boxStyle(box)}
      onClick={onClick}
      type="button"
    >
      <div className="adg-ne-eye">{source.code} · EXT</div>
      <div className="adg-ne-name">{source.name}</div>
      <div className="adg-ne-kind">{source.kind}</div>
      <div className="adg-ne-sla">
        <span>SLA</span>
        <span className="v">{source.sla}</span>
      </div>
    </button>
  )
}

function boxStyle(box: GraphBox) {
  return { left: box.x, top: box.y, width: box.w, height: box.h }
}

function labelForPurchaseOrderStatus(status: string) {
  const labels: Record<string, string> = {
    draft: "Borrador",
    received: "Recibida",
    validated: "Validada",
    in_production: "Produccion",
    shipping: "En embarque",
    completed: "Completa",
    cancelled: "Cancelada",
  }
  return labels[status] || status
}

export function documentStatusMeta(status: string) {
  const labels: Record<string, { label: string; className: string }> = {
    not_started: { label: "Sin iniciar", className: "pill-neutral" },
    blocked: { label: "Bloqueado", className: "pill-crit" },
    pending: { label: "Pendiente", className: "pill-watch" },
    in_review: { label: "Revision", className: "pill-info" },
    approved: { label: "Aprobado", className: "pill-ok" },
    rejected: { label: "Rechazado", className: "pill-crit" },
    waived: { label: "Eximido", className: "pill-ok" },
  }
  return labels[status] || { label: status, className: "pill-neutral" }
}
