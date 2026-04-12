import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface TocItem {
  id: string
  title: string
  type: 'chapter' | 'appendix' | 'part' | 'section' | 'glossary' | 'bibliography' | 'index' | 'reference' | 'preface'
  children: TocItem[]
  number?: string
}

// Block types for structured content (includes both block-level and inline types)
export type BlockType =
  | 'paragraph'
  | 'code'
  | 'image'
  | 'blockquote'
  | 'ordered_list'
  | 'itemized_list'
  | 'list_item'
  | 'definition_list'
  | 'definition_term'
  | 'definition_description'
  | 'bibliography_entry'
  | 'reference_entry'
  | 'reference_meta'
  | 'reference_class'
  | 'reference_badge'
  | 'reference_name'
  | 'reference_definition'
  | 'description_section'
  | 'example_output'
  | 'note'
  | 'warning'
  | 'caution'
  | 'important'
  | 'tip'
  | 'danger'
  | 'section'
  | 'heading'
  // Index types
  | 'index_section'
  | 'index_letter'
  | 'index_entry'
  | 'index_reference'
  | 'index_see'
  | 'index_see_also'
  // Bibliography types
  | 'biblio_abbrev'
  | 'biblio_citetitle'
  | 'biblio_author'
  | 'biblio_personname'
  | 'biblio_firstname'
  | 'biblio_surname'
  | 'biblio_publishername'
  | 'biblio_pubdate'
  | 'biblio_orgname'
  | 'biblio_bibliosource'
  // Inline types (used in children of paragraph blocks)
  | 'text'
  | 'strong'
  | 'italic'
  | 'emphasis'
  | 'codetext'
  | 'link'
  | 'biblioref'
  | 'citation'
  | 'citation_link'
  | 'xref'
  | 'inline_image'

export interface ContentBlock {
  type: BlockType
  text?: string
  src?: string
  alt?: string
  title?: string
  language?: string
  className?: string  // For bibliography elements
  children?: ContentBlock[]
}

export interface SectionContent {
  section_id: string
  blocks: ContentBlock[]
}

// Computed index data from Ruby
export interface IndexTerm {
  primary: string
  secondary?: string
  tertiary?: string
  section_id?: string
  section_title?: string
  sort_as?: string
  sees?: string[]
  see_alsos?: string[]
}

export interface IndexGroup {
  letter: string
  entries: IndexTerm[]
}

export interface IndexData {
  title?: string
  type?: string
  groups: IndexGroup[]
}

export interface DocumentData {
  title: string
  sections: TocItem[]
  numbering: Record<string, string>
  content: Record<string, SectionContent>
  index: IndexData | null
}

export const useDocumentStore = defineStore('document', () => {
  const documentData = ref<DocumentData | null>(null)

  function convertNumbering(numbering: any): Record<string, string> {
    const map: Record<string, string> = {}
    if (Array.isArray(numbering)) {
      // NumberingEntry collection serializes as direct array [{id, value}]
      numbering.forEach((e: { id: string, value: string }) => { map[e.id] = e.value })
    } else if (numbering && typeof numbering === 'object' && Array.isArray(numbering.entries)) {
      numbering.entries.forEach((e: { id: string, value: string }) => { map[e.id] = e.value })
    }
    return map
  }

  function convertContent(content: any): Record<string, SectionContent> {
    const map: Record<string, SectionContent> = {}
    if (content && typeof content === 'object' && Array.isArray(content.entries)) {
      content.entries.forEach((e: { key: string, value: SectionContent }) => { map[e.key] = e.value })
    }
    return map
  }

  function loadFromWindow(): Promise<void> {
    // Check if DOCBOOK_DATA is set (single_file mode with inline JSON)
    const inlineData = (window as any).DOCBOOK_DATA
    if (inlineData && inlineData !== null) {
      const data = inlineData as any

      // Extract sections and numbering from toc model
      if (data.toc) {
        data.sections = data.toc.sections || []
        data.numbering = convertNumbering(data.toc.numbering)
        delete data.toc
      }

      // Content from ContentData model
      data.content = convertContent(data.content)

      // Index is already a proper Index model, keep as-is
      if (!data.index || (data.index && typeof data.index === 'object' && !Array.isArray(data.index.groups) && !Object.keys(data.index).length)) {
        data.index = null
      }

      documentData.value = data as DocumentData
      return Promise.resolve()
    }

    // Otherwise try to fetch from docbook.data.json (directory mode)
    return fetch('docbook.data.json')
      .then(res => {
        if (!res.ok) throw new Error('Failed to load docbook.data.json')
        return res.json()
      })
      .then(data => {
        const d = data as any
        if (d.toc) {
          d.sections = d.toc.sections || []
          d.numbering = convertNumbering(d.toc.numbering)
          delete d.toc
        }
        d.content = convertContent(d.content)
        if (!d.index) d.index = null
        documentData.value = d as DocumentData
      })
      .catch(err => {
        console.error('Failed to load document data:', err)
        documentData.value = null
      })
  }

  const title = computed(() => documentData.value?.title || 'DocBook Document')
  const sections = computed(() => documentData.value?.sections || [])
  const numbering = computed(() => documentData.value?.numbering || {})
  const content = computed(() => documentData.value?.content || {})
  const index = computed(() => documentData.value?.index || null)

  // Get structured content for a section
  function getSectionContent(id: string): SectionContent | null {
    return content.value[id] || null
  }

  // Legacy: get pre-rendered HTML content (for backward compatibility - returns empty string)
  function getContent(_id: string): string {
    return ''
  }

  function getNumbering(id: string): string {
    return numbering.value[id] || ''
  }

  return {
    documentData,
    loadFromWindow,
    title,
    sections,
    numbering,
    content,
    index,
    getSectionContent,
    getContent,
    getNumbering
  }
})
