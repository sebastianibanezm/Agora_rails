import { Link } from "@inertiajs/react"
import { Icon } from "@/components/document_graph/icons"

interface AppShellProps {
  orgSlug: string
  section?: string
  here?: string
  children: React.ReactNode
}

export function AppShell({ orgSlug, section = "Operations", here = "Documents", children }: AppShellProps) {
  return (
    <main className="agora-doc-workspace adg-app">
      <aside className="adg-sidebar" aria-label="Primary">
        <Link className="adg-logo" href={`/${orgSlug}`} aria-label="Agora">
          <span>A</span>
        </Link>
        <Link className="adg-nav-icon" href={`/${orgSlug}`} title="Operations"><Icon.layout /></Link>
        <Link className="adg-nav-icon active" href={`/${orgSlug}/master_agreements`} title="Documents"><Icon.contract /></Link>
        <Link className="adg-nav-icon" href={`/${orgSlug}/shipments`} title="Bookings"><Icon.container /></Link>
        <span className="adg-nav-icon muted" title="Exporters"><Icon.building /></span>
        <span className="adg-nav-icon muted" title="Carriers"><Icon.ship /></span>
        <span className="adg-nav-icon muted" title="Performance"><Icon.bar /></span>
      </aside>
      <div className="adg-main">
        <header className="adg-shell-topbar">
          <div className="adg-crumb">
            <span className="sec">{section}</span>
            <span className="slash">/</span>
            <span className="here">{here}</span>
          </div>
          <div className="adg-topbar-right">
            <div className="adg-search">
              <Icon.search />
              <span>Search contracts, POs, documents...</span>
              <span className="kbd">⌘K</span>
            </div>
            <button className="adg-icon-btn" type="button" title="Filter"><Icon.filter /></button>
            <button className="adg-icon-btn" type="button" title="Notifications"><Icon.bell /></button>
          </div>
        </header>
        <div className="adg-canvas">
          {children}
        </div>
      </div>
    </main>
  )
}

export function PageHead({
  eyebrow,
  title,
  metricLabel,
  metricValue,
}: {
  eyebrow: string
  title: React.ReactNode
  metricLabel?: string
  metricValue?: string
}) {
  return (
    <header className="adg-page-head">
      <div>
        <div className="adg-page-eyebrow">{eyebrow}</div>
        <h1 className="adg-page-title">{title}</h1>
      </div>
      {metricLabel && metricValue && (
        <div className="adg-page-meta">
          <div>{metricLabel}</div>
          <span className="meta-num">{metricValue}</span>
        </div>
      )}
    </header>
  )
}
