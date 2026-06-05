import { Link } from "@inertiajs/react"
import { useMemo, useState } from "react"
import { AppShell, PageHead } from "@/components/agora/AppShell"
import { Icon } from "@/components/document_graph/icons"
import "@/components/document_graph/styles.css"

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

interface Props {
  org_slug: string
  agreements: Agreement[]
  pagination: {
    page: number
    per_page: number
    total_count: number
    total_pages: number
    prev_page?: number | null
    next_page?: number | null
  }
}

type Tab = "all" | "attention" | "active" | "closing"

export default function MasterAgreementsIndex({ org_slug, agreements, pagination }: Props) {
  const [tab, setTab] = useState<Tab>("all")
  const totalValue = agreements.reduce((sum, agreement) => sum + numericValue(agreement.total_amount), 0)
  const counts = {
    all: agreements.length,
    attention: agreements.filter((agreement) => severityForAgreement(agreement) === "watch" || severityForAgreement(agreement) === "crit").length,
    active: agreements.filter((agreement) => agreement.status === "active").length,
    closing: agreements.filter((agreement) => agreement.status === "expired" || agreement.status === "terminated").length,
  }
  const filtered = useMemo(() => agreements.filter((agreement) => {
    if (tab === "attention") return severityForAgreement(agreement) === "watch" || severityForAgreement(agreement) === "crit"
    if (tab === "active") return agreement.status === "active"
    if (tab === "closing") return agreement.status === "expired" || agreement.status === "terminated"
    return true
  }), [agreements, tab])

  return (
    <AppShell orgSlug={org_slug}>
      <PageHead
        eyebrow="Document handling · export season"
        title={<>Every contract, every <em>paper</em> behind it.</>}
        metricLabel="Active contracts"
        metricValue={`${counts.active} · ${compactMoney(totalValue, agreements[0]?.currency)}`}
      />

      <div className="adg-filters">
        <div className="adg-tabs" role="tablist" aria-label="Contract filters">
          <FilterTab id="all" label="All" count={counts.all} active={tab === "all"} onClick={setTab} />
          <FilterTab id="attention" label="Needs attention" count={counts.attention} active={tab === "attention"} onClick={setTab} />
          <FilterTab id="active" label="Active" count={counts.active} active={tab === "active"} onClick={setTab} />
          <FilterTab id="closing" label="Closing" count={counts.closing} active={tab === "closing"} onClick={setTab} />
        </div>
        <button className="adg-chip-btn" type="button"><Icon.filter /> Exporter</button>
        <button className="adg-chip-btn" type="button"><Icon.filter /> Counterparty</button>
        <button className="adg-chip-btn" type="button"><Icon.filter /> Coordinator</button>
        <button className="adg-chip-btn primary" type="button"><Icon.plus /> New</button>
      </div>

      <section className="adg-contracts-grid">
        {filtered.map((agreement) => (
          <ContractCard agreement={agreement} orgSlug={org_slug} key={agreement.id} />
        ))}
        {filtered.length === 0 && (
          <div className="adg-empty-card">
            <span>Sin datos</span>
            <strong>No hay contratos maestros para este filtro.</strong>
          </div>
        )}
      </section>

      <nav className="adg-pagination">
        <p>Pagina {pagination.page} de {pagination.total_pages} · {pagination.total_count} contratos</p>
        <div className="adg-actions">
          {pagination.prev_page ? (
            <Link className="adg-link" href={`/${org_slug}/master_agreements?page=${pagination.prev_page}&per_page=${pagination.per_page}`}>Anterior</Link>
          ) : (
            <span className="adg-link" aria-disabled="true">Anterior</span>
          )}
          {pagination.next_page ? (
            <Link className="adg-link" href={`/${org_slug}/master_agreements?page=${pagination.next_page}&per_page=${pagination.per_page}`}>Siguiente</Link>
          ) : (
            <span className="adg-link" aria-disabled="true">Siguiente</span>
          )}
        </div>
      </nav>
    </AppShell>
  )
}

function FilterTab({ id, label, count, active, onClick }: { id: Tab; label: string; count: number; active: boolean; onClick: (tab: Tab) => void }) {
  return (
    <button className={`adg-tab${active ? " active" : ""}`} type="button" role="tab" aria-selected={active} onClick={() => onClick(id)}>
      <span>{label}</span>
      <span className="count">{count}</span>
    </button>
  )
}

function ContractCard({ agreement, orgSlug }: { agreement: Agreement; orgSlug: string }) {
  const total = agreement.contract_document_progress.total
  const approved = agreement.contract_document_progress.approved
  const pct = total > 0 ? Math.round((approved / total) * 100) : 0
  const severity = severityForAgreement(agreement)

  return (
    <Link className={`adg-contract-card sev-${severity}`} href={`/${orgSlug}/master_agreements/${agreement.id}`}>
      <div className="adg-cc-top">
        <div>
          <div className="adg-cc-id">{agreement.agreement_number}</div>
          <div className="adg-cc-title">{agreement.name}</div>
        </div>
        <div className="adg-cc-status">{labelForAgreementStatus(agreement.status)}</div>
      </div>

      <div className="adg-cc-counterparty">
        {flagForCountry(agreement.trading_partner.country) && <span className="flag">{flagForCountry(agreement.trading_partner.country)}</span>}
        <span><strong>{agreement.trading_partner.name}</strong> · {agreement.trading_partner.legal_name || agreement.trading_partner.country || "counterparty"}</span>
      </div>

      <div className="adg-cc-progress">
        <div className="row">
          <span>Progress</span>
          <strong>{pct}%</strong>
        </div>
        <div className="bar"><div style={{ width: `${pct}%` }} /></div>
      </div>

      <div className={`adg-cc-note ${severity === "ok" ? "" : `sev-${severity}`}`}>
        <Icon.alert />
        <span>{noteForAgreement(agreement, pct)}</span>
      </div>

      <div className="adg-cc-meta">
        <div className="cell value">
          <span>Value</span>
          <strong>{compactMoney(numericValue(agreement.total_amount), agreement.currency)}</strong>
        </div>
        <div className="cell">
          <span>Incoterm</span>
          <strong>{agreement.incoterm || "—"}</strong>
        </div>
        <div className="cell">
          <span>POs</span>
          <strong>{agreement.counts.purchase_orders || "—"}</strong>
        </div>
        <div className="cell">
          <span>Expires</span>
          <strong>{shortDate(agreement.expires_on) || "—"}</strong>
        </div>
      </div>
    </Link>
  )
}

function severityForAgreement(agreement: Agreement) {
  const total = agreement.contract_document_progress.total
  const approved = agreement.contract_document_progress.approved
  if (agreement.status === "terminated") return "crit"
  if (agreement.status === "expired") return "watch"
  if (total > 0 && approved < total) return "watch"
  if (agreement.counts.purchase_orders === 0) return "info"
  return "ok"
}

function noteForAgreement(agreement: Agreement, pct: number) {
  if (agreement.status === "terminated") return "Contract terminated. Review open operational documents."
  if (agreement.status === "expired") return "Contract expired. Validate renewal before new PO release."
  if (agreement.contract_document_progress.total === 0) return "No contract documents generated yet."
  if (pct < 100) return `${agreement.contract_document_progress.approved} of ${agreement.contract_document_progress.total} contract docs released.`
  return `${agreement.counts.shipments} shipment workflows connected.`
}

function labelForAgreementStatus(status: string) {
  const labels: Record<string, string> = {
    draft: "Draft",
    active: "Active",
    expired: "Closing",
    terminated: "Closed",
  }

  return labels[status] || status
}

function numericValue(value?: string | number | null) {
  const amount = Number(value || 0)
  return Number.isNaN(amount) ? 0 : amount
}

function compactMoney(value: number, currency?: string | null) {
  if (value <= 0) return `${currency || "USD"} —`
  if (value >= 1_000_000) return `${currency || "USD"} ${(value / 1_000_000).toFixed(1)}M`
  return `${currency || "USD"} ${(value / 1_000).toFixed(0)}K`
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
