/**
 * Rendering contract between Ruby HtmlRenderer and Vue MirrorRenderer.
 *
 * This file is the single source of truth for the mirror node format.
 * Both renderers must handle every node type listed here with the
 * documented CSS classes and attributes.
 *
 * When adding a new block type:
 *   1. Add it to BLOCK_TYPES below
 *   2. Implement render_{type} in Ruby HtmlRenderer
 *   3. Add a Vue block component and register it in blocks/index.ts
 *   4. Update the cross-validation spec
 */

// ── Inline mark types ──────────────────────────────────────────────

export const MARK_TYPES = [
  'emphasis',
  'strong',
  'italic',
  'code',
  'link',
  'xref',
  'citation',
  'tag',
  'subscript',
  'superscript',
] as const

export type MarkType = (typeof MARK_TYPES)[number]

// ── Section types (rendered by SectionBlock) ───────────────────────

export const SECTION_TYPES = [
  'chapter',
  'section',
  'appendix',
  'part',
  'preface',
  'dedication',
  'acknowledgements',
  'colophon',
  'reference',
  'refentry',
  'glossary',
  'bibliography',
  'index_block',
  'procedure',
  'article',
  'topic',
  'set',
] as const

export type SectionType = (typeof SECTION_TYPES)[number]

// ── Admonition types ───────────────────────────────────────────────

export const ADMONITION_TYPES = [
  'note',
  'warning',
  'tip',
  'caution',
  'important',
  'danger',
] as const

export type AdmonitionType = (typeof ADMONITION_TYPES)[number]

// ── Block type specification ───────────────────────────────────────

export type ChildrenKind = 'inline' | 'block' | 'mixed' | 'none'

export interface BlockTypeSpec {
  /** Mirror node type string */
  nodeType: string
  /** Primary CSS class used by Ruby HtmlRenderer */
  rubyCssClass: string
  /** Primary CSS class(es) used by Vue component */
  vueCssClass: string
  /** Expected attrs keys (excluding xml_id which is universal) */
  attrs: string[]
  /** What kind of children this node contains */
  children: ChildrenKind
}

export const BLOCK_TYPES: BlockTypeSpec[] = [
  // ── Prose ──
  {
    nodeType: 'paragraph',
    rubyCssClass: 'db-paragraph',
    vueCssClass: '',
    attrs: ['xml_id'],
    children: 'inline',
  },
  {
    nodeType: 'blockquote',
    rubyCssClass: 'db-blockquote',
    vueCssClass: '',
    attrs: [],
    children: 'block',
  },
  {
    nodeType: 'synopsis',
    rubyCssClass: 'db-synopsis',
    vueCssClass: '',
    attrs: [],
    children: 'block',
  },

  // ── Code ──
  {
    nodeType: 'code_block',
    rubyCssClass: 'db-code-block',
    vueCssClass: 'code-block',
    attrs: ['xml_id', 'language', 'text', 'title', 'callouts'],
    children: 'none',
  },

  // ── Admonition ──
  {
    nodeType: 'admonition',
    rubyCssClass: 'db-admonition',
    vueCssClass: 'admonition',
    attrs: ['xml_id', 'admonition_type', 'title'],
    children: 'block',
  },

  // ── Media ──
  {
    nodeType: 'image',
    rubyCssClass: 'db-image',
    vueCssClass: '',
    attrs: ['xml_id', 'src', 'alt', 'title'],
    children: 'none',
  },

  // ── Table ──
  {
    nodeType: 'table',
    rubyCssClass: 'db-table',
    vueCssClass: '',
    attrs: ['xml_id', 'title'],
    children: 'block',
  },

  // ── Lists ──
  {
    nodeType: 'ordered_list',
    rubyCssClass: 'db-ordered-list',
    vueCssClass: '',
    attrs: [],
    children: 'block',
  },
  {
    nodeType: 'bullet_list',
    rubyCssClass: 'db-bullet-list',
    vueCssClass: '',
    attrs: [],
    children: 'block',
  },
  {
    nodeType: 'dl',
    rubyCssClass: 'db-definition-list',
    vueCssClass: '',
    attrs: [],
    children: 'block',
  },

  // ── Procedure / Steps ──
  {
    nodeType: 'step',
    rubyCssClass: 'step-item',
    vueCssClass: 'step-item',
    attrs: ['xml_id'],
    children: 'block',
  },
  {
    nodeType: 'substeps',
    rubyCssClass: 'substeps-item',
    vueCssClass: 'substeps-item',
    attrs: [],
    children: 'block',
  },

  // ── Callout ──
  {
    nodeType: 'calloutlist',
    rubyCssClass: 'db-calloutlist',
    vueCssClass: '',
    attrs: ['xml_id', 'title'],
    children: 'block',
  },
  {
    nodeType: 'callout',
    rubyCssClass: 'callout-item',
    vueCssClass: 'callout-item',
    attrs: ['xml_id'],
    children: 'block',
  },

  // ── QandA ──
  {
    nodeType: 'qandaset',
    rubyCssClass: 'db-qandaset',
    vueCssClass: 'qandaset-block',
    attrs: ['xml_id', 'title'],
    children: 'block',
  },
  {
    nodeType: 'qandaentry',
    rubyCssClass: 'db-qandaentry',
    vueCssClass: 'qanda-entry',
    attrs: ['xml_id'],
    children: 'block',
  },
  {
    nodeType: 'question',
    rubyCssClass: 'db-question',
    vueCssClass: 'question-block',
    attrs: [],
    children: 'block',
  },
  {
    nodeType: 'answer',
    rubyCssClass: 'db-answer',
    vueCssClass: 'answer-block',
    attrs: [],
    children: 'block',
  },

  // ── Glossary ──
  {
    nodeType: 'gloss_entry',
    rubyCssClass: '',
    vueCssClass: '',
    attrs: [],
    children: 'block',
  },
  {
    nodeType: 'gloss_term',
    rubyCssClass: 'db-gloss-term',
    vueCssClass: '',
    attrs: [],
    children: 'inline',
  },
  {
    nodeType: 'gloss_def',
    rubyCssClass: 'db-gloss-def',
    vueCssClass: '',
    attrs: [],
    children: 'inline',
  },
  {
    nodeType: 'gloss_see',
    rubyCssClass: 'db-gloss-see',
    vueCssClass: '',
    attrs: ['otherterm'],
    children: 'inline',
  },
  {
    nodeType: 'gloss_see_also',
    rubyCssClass: 'db-gloss-see-also',
    vueCssClass: '',
    attrs: ['otherterm'],
    children: 'inline',
  },

  // ── Bibliography ──
  {
    nodeType: 'biblio_entry',
    rubyCssClass: 'db-biblio-entry',
    vueCssClass: 'biblio-entry',
    attrs: ['xml_id'],
    children: 'inline',
  },

  // ── Index ──
  {
    nodeType: 'index_div',
    rubyCssClass: 'db-index-div',
    vueCssClass: '',
    attrs: ['title'],
    children: 'block',
  },
  {
    nodeType: 'index_entry',
    rubyCssClass: 'db-index-entry',
    vueCssClass: '',
    attrs: [],
    children: 'inline',
  },

  // ── Footnotes ──
  {
    nodeType: 'footnotes',
    rubyCssClass: 'footnotes',
    vueCssClass: 'footnotes',
    attrs: [],
    children: 'block',
  },

  // ── Annotation (interactive-only, not rendered in static HTML) ──
  {
    nodeType: 'annotation',
    rubyCssClass: '',
    vueCssClass: '',
    attrs: ['xml_id'],
    children: 'block',
  },

  // ── Equation ──
  {
    nodeType: 'equation',
    rubyCssClass: 'db-equation',
    vueCssClass: 'equation-block',
    attrs: ['xml_id', 'title'],
    children: 'block',
  },

  // ── Sidebar ──
  {
    nodeType: 'sidebar',
    rubyCssClass: 'db-sidebar',
    vueCssClass: 'sidebar-block',
    attrs: ['xml_id', 'title'],
    children: 'block',
  },

  // ── Refsection (reference page subsection) ──
  {
    nodeType: 'refsection',
    rubyCssClass: 'db-refsection',
    vueCssClass: '',
    attrs: ['title'],
    children: 'block',
  },
]

// ── Derived lookup maps ────────────────────────────────────────────

/** All block node types handled by the block component registry */
export const BLOCK_NODE_TYPES: Set<string> = new Set(BLOCK_TYPES.map((b) => b.nodeType))

/** All section node types handled by SectionBlock */
export const SECTION_NODE_TYPES: Set<string> = new Set(SECTION_TYPES)

/** Complete set of all rendered node types (section + block + special) */
export const ALL_NODE_TYPES: Set<string> = new Set([
  ...SECTION_TYPES,
  ...BLOCK_TYPES.map((b) => b.nodeType),
  'doc',
  'soft_break',
  'text',
  'footnote_marker',
  'list_item',
  'definition_term',
  'definition_description',
  'table_head',
  'table_body',
  'row',
  'cell',
])
