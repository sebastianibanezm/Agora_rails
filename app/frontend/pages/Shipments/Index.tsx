import { Link } from "@inertiajs/react"
import { AppShell, PageHead } from "@/components/agora/AppShell"
import "@/components/document_graph/styles.css"

interface Shipment {
  id: number
  shipment_number: string
  status: string
  etd?: string
  destination_country?: string
  pol?: string
  pod?: string
  booking_number?: string
  purchase_order: {
    po_number: string
    trading_partner_name: string
  }
  document_progress: {
    approved: number
    total: number
  }
}

interface Props {
  org_slug: string
  shipments: Shipment[]
  pagination: {
    page: number
    per_page: number
    total_count: number
    total_pages: number
    prev_page?: number | null
    next_page?: number | null
  }
}

export default function ShipmentsIndex({ org_slug, shipments, pagination }: Props) {
  return (
    <AppShell orgSlug={org_slug}>
      <PageHead
        eyebrow="Document handling · shipment workflows"
        title={<>Every shipment, every <em>release</em> behind it.</>}
        metricLabel="Shipments"
        metricValue={String(pagination.total_count)}
      />

        <section className="adg-card-grid">
          {shipments.map((shipment) => {
            const total = shipment.document_progress.total
            const approved = shipment.document_progress.approved
            const pct = total > 0 ? Math.round((approved / total) * 100) : 0

            return (
              <Link className="adg-shipment-card" href={`/${org_slug}/shipments/${shipment.id}`} key={shipment.id}>
                <div className="adg-card-top">
                  <div>
                    <div className="adg-card-id">{shipment.shipment_number}</div>
                    <div className="adg-card-title">{shipment.purchase_order.trading_partner_name}</div>
                  </div>
                  <div className="adg-card-status">{labelForStatus(shipment.status)}</div>
                </div>
                <div className="adg-card-route">
                  PO {shipment.purchase_order.po_number} · {[shipment.pol, shipment.pod].filter(Boolean).join(" -> ") || "Sin ruta"}
                </div>
                <div className="adg-card-route">
                  ETD {shipment.etd || "sin fecha"} · {shipment.destination_country || "destino pendiente"}
                </div>
                <div className="adg-progress">
                  <div className="adg-progress-row">
                    <span>Documentos liberados</span>
                    <strong>{approved}/{total}</strong>
                  </div>
                  <div className="adg-progress-bar"><div className="adg-progress-fill" style={{ width: `${pct}%` }} /></div>
                </div>
              </Link>
            )
          })}
          {shipments.length === 0 && (
            <div className="adg-metric">
              <span>Sin datos</span>
              <strong>No hay embarques creados.</strong>
            </div>
          )}
        </section>

        <nav className="adg-pagination">
          <p>Pagina {pagination.page} de {pagination.total_pages} · {pagination.total_count} embarques</p>
          <div className="adg-actions">
            {pagination.prev_page ? (
              <Link className="adg-link" href={`/${org_slug}/shipments?page=${pagination.prev_page}&per_page=${pagination.per_page}`}>Anterior</Link>
            ) : (
              <span className="adg-link" aria-disabled="true">Anterior</span>
            )}
            {pagination.next_page ? (
              <Link className="adg-link" href={`/${org_slug}/shipments?page=${pagination.next_page}&per_page=${pagination.per_page}`}>Siguiente</Link>
            ) : (
              <span className="adg-link" aria-disabled="true">Siguiente</span>
            )}
          </div>
        </nav>
    </AppShell>
  )
}

function labelForStatus(status: string) {
  const labels: Record<string, string> = {
    planning: "Planificacion",
    documents_pending: "Documentos pendientes",
    ready_to_ship: "Listo para embarcar",
    shipped: "Embarcado",
    post_zarpe: "Post-zarpe",
    closed: "Cerrado",
    cancelled: "Cancelado",
  }

  return labels[status] || status
}
