import { useEffect, useMemo, useRef, useState } from "react"
import {
  CAT_H,
  CAT_Y,
  GRAPH_W,
  INFO_BOX,
  ROOT,
  SECTION_Y,
  bottomCenter,
  catBox,
  childBox,
  computeChain,
  computeDocLayout,
  enterLeftRail,
  leftCenter,
  smoothV,
  topCenter,
} from "./layout"
import {
  CategoryNode,
  CustomerInfoNode,
  DocNode,
  ExternalNode,
  ItemNode,
  MarketInfoNode,
  PurchaseOrderNode,
  RootNode,
} from "./GraphNodes"
import { DetailPanel } from "./DetailPanel"
import type { ChainSelection, GraphScope, GraphSelection, ShipmentGraph } from "./types"
import "./styles.css"

interface DocumentGraphModalProps {
  graph: ShipmentGraph
  onApprove: (documentId: number) => void
  onWaive: (documentId: number) => void
}

export function DocumentGraphModal({ graph, onApprove, onWaive }: DocumentGraphModalProps) {
  const [category, setCategory] = useState<GraphScope>("purchase_order")
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null)
  const [selection, setSelection] = useState<GraphSelection | null>({ kind: "purchase_order", id: graph.purchase_order.id })
  const [chainSelection, setChainSelection] = useState<ChainSelection | null>(null)
  const wrapRef = useRef<HTMLDivElement>(null)
  const [scale, setScale] = useState(1)

  useEffect(() => {
    setChainSelection(null)
    if (category === "purchase_order") setSelection({ kind: "purchase_order", id: graph.purchase_order.id })
    if (category === "customer") setSelection({ kind: "customer", id: graph.customer.id })
    if (category === "market") setSelection({ kind: "market", id: graph.market.id })
    if (category === "items" && graph.items.length > 0) {
      const first = graph.items[0]
      setSelectedItemId(first.id)
      setSelection({ kind: "item", id: first.id })
    }
  }, [category, graph.customer.id, graph.items, graph.market.id, graph.purchase_order.id])

  useEffect(() => {
    if (!wrapRef.current) return
    const update = () => setScale(Math.min(1, wrapRef.current!.clientWidth / GRAPH_W))
    update()
    const observer = new ResizeObserver(update)
    observer.observe(wrapRef.current)
    return () => observer.disconnect()
  }, [])

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape" && selection) {
        setSelection(null)
        setChainSelection(null)
      }
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [selection])

  const activeDocs = useMemo(() => {
    if (category === "items") {
      if (!selectedItemId) return graph.documents.filter((doc) => doc.scope === "items")
      const itemId = Number(selectedItemId.replace("item-", ""))
      return graph.documents.filter((doc) => doc.scope === "items" && doc.documentable_id === itemId)
    }
    return graph.documents.filter((doc) => doc.scope === category)
  }, [category, graph.documents, selectedItemId])

  const docYStart = SECTION_Y + (category === "customer" || category === "market" ? 238 : 188)
  const dependencies = graph.dependencies.filter((edge) => activeDocs.some((doc) => doc.graph_id === edge.from) && activeDocs.some((doc) => doc.graph_id === edge.to))
  const layout = useMemo(() => computeDocLayout(activeDocs, dependencies, docYStart), [activeDocs, dependencies, docYStart])
  const externalById = new Map(graph.external_sources.map((source) => [source.id, source]))

  const chainSet = useMemo(() => {
    if (chainSelection?.type === "doc") return computeChain(chainSelection.id, activeDocs)
    if (chainSelection?.type === "ext") return new Set(activeDocs.filter((doc) => doc.ext === chainSelection.id).map((doc) => doc.graph_id))
    return null
  }, [activeDocs, chainSelection])

  const chainExtSet = useMemo(() => {
    if (!chainSelection) return new Set<string>()
    if (chainSelection.type === "ext") return new Set([chainSelection.id])
    const set = new Set<string>()
    activeDocs.forEach((doc) => {
      if (chainSet?.has(doc.graph_id) && doc.ext) set.add(doc.ext)
    })
    return set
  }, [activeDocs, chainSelection, chainSet])

  const activeCatIdx = graph.categories.findIndex((candidate) => candidate.id === category)
  const childNodes = childNodeModels(graph, category)
  const parentBox = parentBoxFor(category, childNodes, selectedItemId)
  const canvasH = Math.max(layout.totalBottom + 42, CAT_Y + CAT_H + 260)

  const catEdges = graph.categories.map((cat, index) => {
    const box = catBox(index)
    const active = cat.id === category
    return { id: cat.id, d: smoothV(bottomCenter(ROOT), topCenter(box)), className: active ? "active" : "dim" }
  })

  const childEdges = childNodes.map((child, index) => {
    const active = isChildActive(category, child.id, selectedItemId)
    return {
      id: child.id,
      d: smoothV(bottomCenter(catBox(activeCatIdx)), topCenter(child.box)),
      className: active ? "active" : childNodes.length === 1 ? "active" : "dim",
    }
  })

  const parentToDocEdges = (() => {
    if (!parentBox || activeDocs.length === 0) return []
    const firstStack = layout.stacks[layout.stackIdxs[0]] || []
    const firstBox = firstStack[0] ? layout.docBox.get(firstStack[0].graph_id) : undefined
    const railX = (firstBox?.x || 240) - 50
    return firstStack.map((doc) => ({
      id: `p2d-${doc.graph_id}`,
      d: enterLeftRail(bottomCenter(parentBox), leftCenter(layout.docBox.get(doc.graph_id)!), railX),
      className: chainSet ? (chainSet.has(doc.graph_id) ? "active" : "dim") : "active",
    }))
  })()

  const selectDoc = (docId: string) => {
    const isSelected = chainSelection?.type === "doc" && chainSelection.id === docId
    setChainSelection(isSelected ? null : { type: "doc", id: docId })
    setSelection({ kind: "doc", id: docId })
  }

  const selectExternal = (externalId: string) => {
    const isSelected = chainSelection?.type === "ext" && chainSelection.id === externalId
    setChainSelection(isSelected ? null : { type: "ext", id: externalId })
    setSelection({ kind: "ext", id: externalId })
  }

  return (
    <div className={`adg-graph-workspace${selection ? " panel-open" : ""}`}>
      <div className="adg-workspace-main">
        <div className="adg-graph-shell">
          <div className="adg-graph-toolbar">
            <div>
              <div className="adg-eyebrow">Workspace documentario</div>
              <h2>{graph.root.label}</h2>
            </div>
            <div className="adg-toolbar-meta">
              <span>{graph.root.buyer}</span>
              <span>PO {graph.root.po_number}</span>
              <span>{graph.documents.length} documentos</span>
            </div>
          </div>

          <div className="adg-graph-body" ref={wrapRef}>
            <div className="adg-graph-fit" style={{ height: canvasH * scale }}>
              <div className="adg-graph" style={{ height: canvasH, transform: `scale(${scale})` }}>
                <svg className="adg-graph-svg adg-graph-svg-back" viewBox={`0 0 ${GRAPH_W} ${canvasH}`}>
                  {layout.extPaths.map((edge) => (
                    <path key={edge.id} className={`ext ${chainSet ? (chainSet.has(edge.docId) ? "active" : "dim") : "active"}`} d={edge.d} />
                  ))}
                </svg>
                <svg className="adg-graph-svg" viewBox={`0 0 ${GRAPH_W} ${canvasH}`}>
                  {catEdges.map((edge) => <path key={edge.id} className={edge.className} d={edge.d} />)}
                  {childEdges.map((edge) => <path key={edge.id} className={edge.className} d={edge.d} />)}
                  {parentToDocEdges.map((edge) => <path key={edge.id} className={edge.className} d={edge.d} />)}
                  {layout.depPaths.map((edge) => (
                    <path
                      key={edge.id}
                      className={`dep ${chainSet ? (chainSet.has(edge.from) && chainSet.has(edge.to) ? "active" : "dim") : "active"}`}
                      d={edge.d}
                    />
                  ))}
                </svg>

                <RootNode root={graph.root} box={ROOT} active={!!category} onClick={() => setSelection({ kind: "root", id: graph.root.id })} />

                <div className="adg-row-label" style={{ left: 76, top: CAT_Y - 22 }}>Explorar por · {graph.categories.length}</div>
                {graph.categories.map((cat, index) => (
                  <CategoryNode
                    key={cat.id}
                    category={cat}
                    box={catBox(index)}
                    active={category === cat.id}
                    dimmed={category !== cat.id}
                    onClick={() => setCategory(cat.id)}
                  />
                ))}

                <div className="adg-row-label" style={{ left: childNodes[0]?.box.x || INFO_BOX.x, top: SECTION_Y - 22 }}>{sectionLabel(category, activeDocs.length)}</div>
                {category === "purchase_order" && (
                  <PurchaseOrderNode purchaseOrder={graph.purchase_order} box={childBox(0, 1)} active onClick={() => setSelection({ kind: "purchase_order", id: graph.purchase_order.id })} />
                )}
                {category === "items" && graph.items.map((item, index) => (
                  <ItemNode
                    key={item.id}
                    item={item}
                    box={childBox(index, graph.items.length)}
                    active={selectedItemId === item.id}
                    dimmed={!!selectedItemId && selectedItemId !== item.id}
                    onClick={() => {
                      setSelectedItemId(selectedItemId === item.id ? null : item.id)
                      setChainSelection(null)
                      setSelection({ kind: "item", id: item.id })
                    }}
                  />
                ))}
                {category === "customer" && <CustomerInfoNode customer={graph.customer} box={INFO_BOX} onClick={() => setSelection({ kind: "customer", id: graph.customer.id })} />}
                {category === "market" && <MarketInfoNode market={graph.market} box={INFO_BOX} onClick={() => setSelection({ kind: "market", id: graph.market.id })} />}

                <div className="adg-row-label" style={{ left: 40, top: docYStart - 22 }}>Documentos · {activeDocs.length}</div>
                {activeDocs.map((doc) => {
                  const box = layout.docBox.get(doc.graph_id)
                  if (!box) return null
                  const selected = chainSelection?.type === "doc" && chainSelection.id === doc.graph_id
                  return (
                    <DocNode
                      key={doc.graph_id}
                      doc={doc}
                      box={box}
                      dimmed={!!chainSet && !chainSet.has(doc.graph_id)}
                      active={!!chainSet && chainSet.has(doc.graph_id)}
                      selected={selected}
                      onClick={() => selectDoc(doc.graph_id)}
                    />
                  )
                })}

                {layout.extUsed.length > 0 && (
                  <div className="adg-row-label" style={{ left: layout.extBox.get(layout.extUsed[0])?.x || 40, top: (layout.extBox.get(layout.extUsed[0])?.y || 0) - 22 }}>
                    Proveedores externos · {layout.extUsed.length}
                  </div>
                )}
                {layout.extUsed.map((id) => {
                  const source = externalById.get(id)
                  const box = layout.extBox.get(id)
                  if (!source || !box) return null
                  const selected = chainSelection?.type === "ext" && chainSelection.id === id
                  return (
                    <ExternalNode
                      key={id}
                      source={source}
                      box={box}
                      dimmed={!!chainSet && !chainExtSet.has(id)}
                      active={!!chainSet && chainExtSet.has(id)}
                      selected={selected}
                      onClick={() => selectExternal(id)}
                    />
                  )
                })}

                {activeDocs.length === 0 && (
                  <div className="adg-graph-hint" style={{ top: docYStart + 20 }}>No hay documentos runtime para este lente</div>
                )}

                <div className="adg-graph-legend">
                  <span><i className="route" />ruta</span>
                  <span><i className="dep" />depende de</span>
                  <span><i className="ext" />externo</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <DetailPanel graph={graph} selection={selection} onClose={() => setSelection(null)} onSelect={setSelectionFromPanel} onApprove={onApprove} onWaive={onWaive} />
    </div>
  )

  function setSelectionFromPanel(nextSelection: GraphSelection) {
    setSelection(nextSelection)
    if (nextSelection.kind === "doc") setChainSelection({ type: "doc", id: nextSelection.id })
    if (nextSelection.kind === "ext") setChainSelection({ type: "ext", id: nextSelection.id })
  }
}

function childNodeModels(graph: ShipmentGraph, category: GraphScope) {
  if (category === "purchase_order") return [{ id: graph.purchase_order.id, box: childBox(0, 1) }]
  if (category === "items") return graph.items.map((item, index) => ({ id: item.id, box: childBox(index, graph.items.length) }))
  return [{ id: category, box: INFO_BOX }]
}

function isChildActive(category: GraphScope, id: string, selectedItemId: string | null) {
  if (category === "items") return !selectedItemId || selectedItemId === id
  return true
}

function parentBoxFor(category: GraphScope, childNodes: Array<{ id: string; box: { x: number; y: number; w: number; h: number } }>, selectedItemId: string | null) {
  if (category === "items") {
    return childNodes.find((child) => child.id === selectedItemId)?.box || childNodes[0]?.box
  }
  return childNodes[0]?.box || INFO_BOX
}

function sectionLabel(category: GraphScope, docsCount: number) {
  const labels: Record<GraphScope, string> = {
    purchase_order: "Orden de compra",
    items: "Items",
    customer: "Cliente",
    market: "Mercado destino",
  }
  return `${labels[category]} · ${docsCount} docs`
}

export default DocumentGraphModal
