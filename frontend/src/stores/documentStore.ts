import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

// ============================================================
// DocbookMirror (ProseMirror-style) Types
// ============================================================

export interface MirrorMark {
  type: 'emphasis' | 'strong' | 'italic' | 'code' | 'link' | 'xref' | 'citation' | 'tag'
  attrs?: Record<string, any>
}

export interface MirrorTextNode {
  type: 'text'
  text: string
  marks?: MirrorMark[]
}

export interface MirrorBlockNode {
  type: string
  attrs?: Record<string, any>
  content?: (MirrorTextNode | MirrorBlockNode)[]
}

export interface MirrorDocument {
  type: 'doc'
  attrs?: Record<string, any>
  content?: MirrorBlockNode[]
}

// ============================================================
// TOC Types
// ============================================================

export interface TocItem {
  id: string
  title: string
  type: 'chapter' | 'appendix' | 'part' | 'section' | 'glossary' | 'bibliography' | 'index' | 'reference' | 'preface'
  children: TocItem[]
  number?: string
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

interface DocumentMeta {
  title?: string
  sections: TocItem[]
  numbering: Record<string, string>
  index: IndexData | null
}

// ============================================================
// Document Store
// ============================================================

export const useDocumentStore = defineStore('document', () => {
  const documentMeta = ref<DocumentMeta | null>(null)
  const mirrorDocument = ref<MirrorDocument | null>(null)

  function convertNumbering(numbering: any): Record<string, string> {
    const map: Record<string, string> = {}
    if (Array.isArray(numbering)) {
      numbering.forEach((e: { id: string, value: string }) => { map[e.id] = e.value })
    } else if (numbering && typeof numbering === 'object' && Array.isArray(numbering.entries)) {
      numbering.entries.forEach((e: { id: string, value: string }) => { map[e.id] = e.value })
    }
    return map
  }

  function processDocbookData(data: any): Promise<void> {
    // DocbookMirror format: has type: 'doc' and content array of nodes
    if (data.type === 'doc' && Array.isArray(data.content)) {
      mirrorDocument.value = data as MirrorDocument
      // Extract sections and numbering from toc if present
      if (data.toc?.sections) {
        documentMeta.value = {
          sections: data.toc.sections,
          numbering: data.toc.numbering || {},
          index: data.toc.index || null
        }
      }
      return Promise.resolve()
    }

    // Standalone TOC data (without mirror content)
    if (data.toc) {
      documentMeta.value = {
        sections: data.toc.sections || [],
        numbering: convertNumbering(data.toc.numbering),
        index: data.index || null
      }
    }

    return Promise.resolve()
  }

  function loadFromWindow(): Promise<void> {
    const inlineData = (window as any).DOCBOOK_DATA
    if (inlineData && inlineData !== null) {
      return processDocbookData(inlineData)
    }

    const collection = (window as any).DOCBOOK_COLLECTION
    if (collection && collection.books && collection.books.length > 0) {
      const firstBook = collection.books[0]
      if (firstBook.data) {
        return processDocbookData(firstBook.data)
      }
    }

    return fetch('docbook.data.json')
      .then(res => {
        if (!res.ok) throw new Error('Failed to load docbook.data.json')
        return res.json()
      })
      .then(data => processDocbookData(data))
      .catch(err => {
        console.error('Failed to load document data:', err)
        documentMeta.value = null
      })
  }

  const title = computed(() => {
    if (mirrorDocument.value?.attrs?.title) {
      return mirrorDocument.value.attrs.title
    }
    return documentMeta.value?.title || 'DocBook Document'
  })
  const sections = computed(() => documentMeta.value?.sections || [])
  const numbering = computed(() => documentMeta.value?.numbering || {})
  const index = computed(() => documentMeta.value?.index || null)

  function getNumbering(id: string): string {
    return numbering.value[id] || ''
  }

  return {
    mirrorDocument,
    loadFromWindow,
    title,
    sections,
    numbering,
    index,
    getNumbering
  }
})
