import type { GraphBox, GraphDependency, GraphDocument } from "./types"

export const GRAPH_W = 1280
export const ROOT: GraphBox = { x: 480, y: 24, w: 320, h: 104 }
export const CAT_W = 250
export const CAT_H = 110
export const CAT_GAP = 32
export const CAT_Y = 188
export const CAT_LEFT = (GRAPH_W - (4 * CAT_W + 3 * CAT_GAP)) / 2
export const SECTION_Y = CAT_Y + CAT_H + 72
export const INFO_BOX: GraphBox = { x: 280, y: SECTION_Y, w: 720, h: 168 }
export const CHILD_W = 230
export const CHILD_H = 108
export const CHILD_GAP = 32
export const DOC_W = 220
export const DOC_H = 114
export const DOC_COL_GAP = 90
export const DOC_ROW_GAP = 16
export const EXT_W = 170
export const EXT_H = 84
export const EXT_GAP = 30

export function catBox(index: number): GraphBox {
  return { x: CAT_LEFT + index * (CAT_W + CAT_GAP), y: CAT_Y, w: CAT_W, h: CAT_H }
}

export function childBox(index: number, count: number): GraphBox {
  const totalW = count * CHILD_W + Math.max(0, count - 1) * CHILD_GAP
  const left = Math.max(40, (GRAPH_W - totalW) / 2)
  return { x: left + index * (CHILD_W + CHILD_GAP), y: SECTION_Y, w: CHILD_W, h: CHILD_H }
}

export function bottomCenter(box: GraphBox) {
  return { x: box.x + box.w / 2, y: box.y + box.h }
}

export function topCenter(box: GraphBox) {
  return { x: box.x + box.w / 2, y: box.y }
}

export function leftCenter(box: GraphBox) {
  return { x: box.x, y: box.y + box.h / 2 }
}

export function rightCenter(box: GraphBox) {
  return { x: box.x + box.w, y: box.y + box.h / 2 }
}

export function smoothV(from: { x: number; y: number }, to: { x: number; y: number }) {
  const dy = to.y - from.y
  const k = Math.max(30, Math.abs(dy) * 0.55)
  return `M ${from.x} ${from.y} C ${from.x} ${from.y + k}, ${to.x} ${to.y - k}, ${to.x} ${to.y}`
}

export function enterLeftRail(from: { x: number; y: number }, to: { x: number; y: number }, railX: number) {
  const k = Math.min(30, Math.max(12, (to.y - from.y) * 0.25))
  const py2 = from.y + k * 2
  const ty0 = Math.max(py2 + 1, to.y - k)
  return `M ${from.x} ${from.y} C ${from.x} ${from.y + k}, ${railX} ${py2 - k}, ${railX} ${py2} L ${railX} ${ty0} C ${railX} ${ty0 + k}, ${to.x - k} ${to.y}, ${to.x} ${to.y}`
}

function depAdjacent(srcBox: GraphBox, dstBox: GraphBox, railX: number) {
  const from = rightCenter(srcBox)
  const to = leftCenter(dstBox)
  const dy = to.y - from.y
  if (Math.abs(dy) < 4) return `M ${from.x} ${from.y} L ${to.x} ${to.y}`
  const sign = Math.sign(dy)
  const k = 22
  return `M ${from.x} ${from.y} C ${from.x + k * 1.5} ${from.y}, ${railX} ${from.y}, ${railX} ${from.y + sign * k} L ${railX} ${to.y - sign * k} C ${railX} ${to.y}, ${to.x - k * 1.5} ${to.y}, ${to.x} ${to.y}`
}

function depSkip(srcBox: GraphBox, dstBox: GraphBox, dipY: number, railSrc: number, railDst: number) {
  const from = rightCenter(srcBox)
  const to = leftCenter(dstBox)
  const k = 22
  return `M ${from.x} ${from.y} C ${from.x + k * 1.5} ${from.y}, ${railSrc} ${from.y}, ${railSrc} ${from.y + k} L ${railSrc} ${dipY - k} C ${railSrc} ${dipY}, ${railSrc + k * 1.5} ${dipY}, ${railSrc + k * 2} ${dipY} L ${railDst - k * 2} ${dipY} C ${railDst - k * 1.5} ${dipY}, ${railDst} ${dipY}, ${railDst} ${dipY - k} L ${railDst} ${to.y + k} C ${railDst} ${to.y}, ${to.x - k * 1.5} ${to.y}, ${to.x} ${to.y}`
}

export function computeChain(selectedId: string | null, docs: GraphDocument[]) {
  if (!selectedId) return null
  const byId = new Map(docs.map((doc) => [doc.graph_id, doc]))
  if (!byId.has(selectedId)) return null
  const set = new Set<string>([selectedId])
  const ancestors = [selectedId]
  while (ancestors.length) {
    const id = ancestors.pop()
    const doc = id ? byId.get(id) : undefined
    doc?.deps.forEach((dep) => {
      if (!set.has(dep) && byId.has(dep)) {
        set.add(dep)
        ancestors.push(dep)
      }
    })
  }
  const descendants = [selectedId]
  while (descendants.length) {
    const id = descendants.pop()
    docs.forEach((doc) => {
      if (id && doc.deps.includes(id) && !set.has(doc.graph_id)) {
        set.add(doc.graph_id)
        descendants.push(doc.graph_id)
      }
    })
  }
  return set
}

export function computeDocLayout(docs: GraphDocument[], dependencies: GraphDependency[], yStart: number) {
  const byId = new Map(docs.map((doc) => [doc.graph_id, doc]))
  const stackOf = new Map<string, number>()

  function stack(id: string, seen = new Set<string>()): number {
    if (stackOf.has(id)) return stackOf.get(id) || 0
    if (seen.has(id)) return 0
    seen.add(id)
    const doc = byId.get(id)
    const internal = (doc?.deps || []).filter((dep) => byId.has(dep))
    if (!internal.length) {
      stackOf.set(id, 0)
      return 0
    }
    const value = Math.max(...internal.map((dep) => stack(dep, seen))) + 1
    stackOf.set(id, value)
    return value
  }

  docs.forEach((doc) => stack(doc.graph_id))
  const stacks: Record<number, GraphDocument[]> = {}
  docs.forEach((doc) => {
    const index = stackOf.get(doc.graph_id) || 0
    stacks[index] ||= []
    stacks[index].push(doc)
  })

  const stackIdxs = Object.keys(stacks).map(Number).sort((a, b) => a - b)
  const rowOf = new Map<string, number>()
  stackIdxs.forEach((stackIdx, physicalIdx) => {
    if (physicalIdx > 0) {
      stacks[stackIdx].sort((a, b) => averageRow(a.deps, rowOf) - averageRow(b.deps, rowOf))
    }
    stacks[stackIdx].forEach((doc, row) => rowOf.set(doc.graph_id, row))
  })

  const totalW = stackIdxs.length * DOC_W + Math.max(0, stackIdxs.length - 1) * DOC_COL_GAP
  const left = Math.max(40, (GRAPH_W - totalW) / 2)
  const colX = (physicalIdx: number) => left + physicalIdx * (DOC_W + DOC_COL_GAP)
  const gapRailX = (physicalIdx: number) => colX(physicalIdx) + DOC_W + DOC_COL_GAP / 2
  const docBox = new Map<string, GraphBox>()
  const stackBottom = new Map<number, number>()

  stackIdxs.forEach((stackIdx, physicalIdx) => {
    stacks[stackIdx].forEach((doc, row) => {
      const box = { x: colX(physicalIdx), y: yStart + row * (DOC_H + DOC_ROW_GAP), w: DOC_W, h: DOC_H }
      docBox.set(doc.graph_id, box)
      stackBottom.set(physicalIdx, Math.max(stackBottom.get(physicalIdx) || 0, box.y + box.h))
    })
  })

  const docsBottom = Math.max(yStart + DOC_H, ...stackBottom.values())
  const extUsed = docs.reduce<string[]>((acc, doc) => {
    if (doc.ext && !acc.includes(doc.ext)) acc.push(doc.ext)
    return acc
  }, [])
  const extBox = new Map<string, GraphBox>()
  const extY = docsBottom + 60
  const extTotalW = extUsed.length * EXT_W + Math.max(0, extUsed.length - 1) * EXT_GAP
  const extLeft = Math.max(40, (GRAPH_W - extTotalW) / 2)
  extUsed.forEach((id, index) => extBox.set(id, { x: extLeft + index * (EXT_W + EXT_GAP), y: extY, w: EXT_W, h: EXT_H }))

  const depEdges = dependencies.flatMap((edge) => {
    if (!docBox.has(edge.from) || !docBox.has(edge.to)) return []
    const fromCol = stackIdxs.indexOf(stackOf.get(edge.from) || 0)
    const toCol = stackIdxs.indexOf(stackOf.get(edge.to) || 0)
    return [{
      ...edge,
      fromBox: docBox.get(edge.from)!,
      toBox: docBox.get(edge.to)!,
      fromCol,
      toCol,
      railSrc: gapRailX(fromCol),
      railDst: gapRailX(toCol - 1),
    }]
  })

  const depPaths = depEdges.map((edge) => {
    const span = edge.toCol - edge.fromCol
    if (span > 1) {
      let interveningBottom = 0
      for (let col = edge.fromCol + 1; col <= edge.toCol - 1; col += 1) {
        interveningBottom = Math.max(interveningBottom, stackBottom.get(col) || 0)
      }
      return { id: edge.id, from: edge.from, to: edge.to, d: depSkip(edge.fromBox, edge.toBox, interveningBottom + 32, edge.railSrc, edge.railDst) }
    }
    return { id: edge.id, from: edge.from, to: edge.to, d: depAdjacent(edge.fromBox, edge.toBox, edge.railSrc) }
  })

  const extPaths = docs.flatMap((doc) => {
    if (!doc.ext || !docBox.has(doc.graph_id) || !extBox.has(doc.ext)) return []
    return [{ id: `ext-${doc.graph_id}-${doc.ext}`, docId: doc.graph_id, extId: doc.ext, d: smoothV(bottomCenter(docBox.get(doc.graph_id)!), topCenter(extBox.get(doc.ext)!)) }]
  })

  return {
    docBox,
    extBox,
    extUsed,
    stacks,
    stackIdxs,
    docsBottom,
    totalBottom: extUsed.length ? extY + EXT_H : docsBottom,
    depPaths,
    extPaths,
  }
}

function averageRow(deps: string[], rowOf: Map<string, number>) {
  const rows = deps.filter((dep) => rowOf.has(dep)).map((dep) => rowOf.get(dep) || 0)
  return rows.length ? rows.reduce((sum, row) => sum + row, 0) / rows.length : 999
}
