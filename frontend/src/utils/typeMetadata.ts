/**
 * Canonical metadata for DocBook section/block types.
 * Single source of truth for labels, badge colors, heading config, and section classification.
 */

// Section-like types that support lazy rendering
export const SECTION_TYPES = new Set([
  'chapter', 'section', 'appendix', 'part', 'preface',
  'dedication', 'acknowledgements', 'colophon', 'glossary',
  'bibliography', 'reference', 'refentry', 'procedure',
  'article', 'topic', 'set', 'index_block',
])

export function isSectionType(type: string): boolean {
  return SECTION_TYPES.has(type)
}

// Heading configuration for section-like types
export interface SectionMeta {
  tag: 'section' | 'article'
  headingTag: string
  headingClass: string
  noAnchor?: boolean
  noNumbering?: boolean
  mono?: boolean
  contentWrapper?: {
    tag: string
    class: string
  }
}

export const SECTION_META: Record<string, SectionMeta> = {
  part: {
    tag: 'section',
    headingTag: 'h1',
    headingClass: 'text-3xl font-bold mb-4',
  },
  chapter: {
    tag: 'section',
    headingTag: 'h1',
    headingClass: 'text-2xl font-bold mb-4',
  },
  section: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
  },
  appendix: {
    tag: 'section',
    headingTag: 'h1',
    headingClass: 'text-2xl font-bold mb-4',
  },
  reference: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-2xl font-bold mb-4',
    noNumbering: true,
  },
  refentry: {
    tag: 'article',
    headingTag: 'div',
    headingClass: 'text-lg font-bold font-mono mb-3',
    noAnchor: true,
    noNumbering: true,
  },
  preface: {
    tag: 'section',
    headingTag: 'h1',
    headingClass: 'text-2xl font-bold mb-4',
  },
  dedication: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3 text-center',
    contentWrapper: { tag: 'div', class: 'max-w-lg mx-auto text-center italic' },
  },
  acknowledgements: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
  },
  colophon: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
  },
  glossary: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
    contentWrapper: { tag: 'dl', class: 'glossary-list' },
  },
  bibliography: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
  },
  index_block: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
  },
  procedure: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-lg font-semibold mb-3',
    contentWrapper: { tag: 'ol', class: 'procedure-list' },
  },
  set: {
    tag: 'section',
    headingTag: 'h1',
    headingClass: 'text-3xl font-bold mb-4',
  },
  article: {
    tag: 'article',
    headingTag: 'h1',
    headingClass: 'text-2xl font-bold mb-4',
  },
  topic: {
    tag: 'section',
    headingTag: 'h2',
    headingClass: 'text-xl font-semibold mb-3',
  },
}

// Type labels for badges (TOC, breadcrumbs)
export function getTypeLabel(type: string): string {
  switch (type) {
    case 'part': return 'Pt'
    case 'chapter': return 'Ch'
    case 'appendix': return 'App'
    case 'section': return ''
    case 'glossary': return 'Gl'
    case 'bibliography': return 'Bib'
    case 'index': return 'Idx'
    case 'preface': return 'Pref'
    case 'dedication': return 'Ded'
    case 'acknowledgements': return 'Ack'
    case 'colophon': return 'Col'
    case 'reference': return 'Ref'
    case 'refentry': return 'p'
    case 'set': return 'Set'
    case 'article': return 'Art'
    case 'topic': return 'Top'
    default: return ''
  }
}

// Badge color class (for TOC, breadcrumbs)
export function getTypeBadgeClass(type: string): string {
  switch (type) {
    case 'part': return 'badge-purple'
    case 'chapter': return 'badge-blue'
    case 'appendix': return 'badge-green'
    case 'section': return 'badge-neutral'
    case 'glossary': return 'badge-yellow'
    case 'bibliography': return 'badge-red'
    case 'index': return 'badge-indigo'
    case 'preface': return 'badge-orange'
    case 'dedication': return 'badge-muted'
    case 'acknowledgements': return 'badge-muted'
    case 'colophon': return 'badge-muted'
    case 'reference': return 'badge-cyan'
    case 'refentry': return 'badge-neutral badge-mono'
    default: return 'badge-neutral'
  }
}
