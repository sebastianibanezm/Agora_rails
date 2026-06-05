import { Link, router } from "@inertiajs/react"
import { AppShell, PageHead } from "@/components/agora/AppShell"
import { DocumentGraphModal } from "@/components/document_graph/DocumentGraphModal"
import type { ShipmentGraph, SourceOfTruthCheck } from "@/components/document_graph/types"

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
  shipment: Shipment
  graph: ShipmentGraph
  source_of_truth_checks: SourceOfTruthCheck[]
}

export default function ShipmentsShow({ org_slug, shipment, graph, source_of_truth_checks }: Props) {
  function approve(documentId: number) {
    router.post(`/${org_slug}/shipment_documents/${documentId}/approve`, {}, { preserveScroll: true })
  }

  function waive(documentId: number) {
    router.post(`/${org_slug}/shipment_documents/${documentId}/waive`, {}, { preserveScroll: true })
  }

  function validateSourceOfTruth() {
    router.post(`/${org_slug}/shipments/${shipment.id}/validate_source_of_truth`, {}, { preserveScroll: true })
  }

  const progress = shipment.document_progress.total > 0
    ? Math.round((shipment.document_progress.approved / shipment.document_progress.total) * 100)
    : 0

  return (
    <AppShell orgSlug={org_slug}>
      <PageHead
        eyebrow="Flow · shipment checklist"
        title={<>{shipment.shipment_number}</>}
        metricLabel="Documents"
        metricValue={`${shipment.document_progress.approved}/${shipment.document_progress.total}`}
      />
      <div className="adg-actions adg-context-actions">
        <Link className="adg-link" href={`/${org_slug}/shipments`}>Embarques</Link>
        <button className="adg-action primary" type="button" onClick={validateSourceOfTruth}>
          Validar consistencia
        </button>
      </div>

        <section className="adg-metric-grid">
          <Metric label="Cliente" value={shipment.purchase_order.trading_partner_name} />
          <Metric label="Ruta" value={[shipment.pol, shipment.pod].filter(Boolean).join(" -> ") || "Sin ruta"} />
          <Metric label="ETD" value={shipment.etd || "Sin fecha"} />
          <Metric label="Documentos" value={`${shipment.document_progress.approved}/${shipment.document_progress.total} · ${progress}%`} />
        </section>

        <DocumentGraphModal graph={graph} onApprove={approve} onWaive={waive} />

        <section className="adg-metric-grid" style={{ marginTop: 18 }}>
          <Metric label="Fuente de verdad" value={`${source_of_truth_checks.length} validaciones`} />
          <Metric label="Diferencias" value={`${source_of_truth_checks.filter((check) => check.status === "mismatch").length}`} />
          <Metric label="Destino" value={shipment.destination_country || "Sin destino"} />
          <Metric label="Booking" value={shipment.booking_number || "Sin booking"} />
        </section>
    </AppShell>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="adg-metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  )
}
