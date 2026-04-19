import type { TocItem } from '@/stores/documentStore'

export interface AncestorItem {
  id: string
  title: string
  type: string
  number: string
  isRoot: boolean
  isLeaf: boolean
}

/**
 * Walk the TOC tree and return the full ancestor chain for a given section ID.
 * Returns [root, ...intermediates, active] or empty array if not found.
 */
export function findAncestorChain(sections: TocItem[], activeId: string): TocItem[] {
  const result = walk(sections, activeId, [])
  return result || []
}

function walk(nodes: TocItem[], targetId: string, path: TocItem[]): TocItem[] | null {
  for (const node of nodes) {
    const currentPath = [...path, node]
    if (node.id === targetId) return currentPath
    if (node.children?.length) {
      const found = walk(node.children, targetId, currentPath)
      if (found) return found
    }
  }
  return null
}

// Re-export type metadata from the canonical source
export { getTypeLabel, getTypeBadgeClass } from '@/utils/typeMetadata'
