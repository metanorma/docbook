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

export function getTypeLabel(type: string): string {
  switch (type) {
    case 'part': return 'Pt'
    case 'chapter': return 'Ch'
    case 'appendix': return 'App'
    case 'glossary': return 'Gl'
    case 'bibliography': return 'Bib'
    case 'index': return 'Idx'
    case 'preface': return 'Pref'
    case 'reference': return 'Ref'
    case 'refentry': return 'p'
    default: return ''
  }
}

export function getTypeBadgeClass(type: string): string {
  switch (type) {
    case 'part':
      return 'badge-purple'
    case 'chapter':
      return 'badge-blue'
    case 'appendix':
      return 'badge-green'
    case 'glossary':
      return 'badge-yellow'
    case 'bibliography':
      return 'badge-red'
    case 'index':
      return 'badge-indigo'
    case 'preface':
      return 'badge-orange'
    case 'reference':
      return 'badge-cyan'
    case 'refentry':
      return 'badge-refentry'
    default:
      return 'badge-default'
  }
}
