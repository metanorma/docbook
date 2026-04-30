import { defineStore } from 'pinia'
import { ref, shallowRef, computed } from 'vue'
import { createContentLoader, getOutputFormat, getCachedPreload } from '@/composables/useContentLoader'
import { useChunkedLoader, type SectionManifest } from '@/composables/useChunkedLoader'

// ============================================================
// DocbookMirror (ProseMirror-style) Types
// ============================================================

export interface MirrorMark {
  type: 'emphasis' | 'strong' | 'italic' | 'code' | 'link' | 'xref' | 'citation' | 'tag' | 'subscript' | 'superscript'
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
  type: string
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

export interface ListOfEntry {
  id?: string
  title: string
  number?: string
  section_id?: string
  section_title?: string
}

export interface ListOfData {
  figures: ListOfEntry[]
  tables: ListOfEntry[]
  examples: ListOfEntry[]
}

interface DocumentMeta {
  title?: string
  subtitle?: string
  author?: string
  pubdate?: string
  releaseinfo?: string
  copyright?: string
  root_element?: string
  cover?: string
  sections: TocItem[]
  numbering: Record<string, string>
  index: IndexData | null
  list_of?: ListOfData
}

// ============================================================
// Document Store
// ============================================================

export const useDocumentStore = defineStore('document', () => {
  const documentMeta = ref<DocumentMeta | null>(null)
  const mirrorDocument = shallowRef<MirrorDocument | null>(null)
  const isChunkedMode = ref(false)
  const chunkedContent = ref<any[]>([])
  const loadError = ref<string | null>(null)

  // Lazy-load sections from IndexedDB before assembling
  function loadChunkedSection(sectionId: string): void {
    const loader = useChunkedLoader()
    loader.loadSection(sectionId).then(() => {
      chunkedContent.value = loader.getAssembledContent()
      mirrorDocument.value = {
        type: 'doc',
        content: chunkedContent.value,
      }
    })
  }

  // Handle chunked format: load manifest, then initial sections
  async function loadChunked(): Promise<void> {
    const loader = useChunkedLoader()
    isChunkedMode.value = true

    const manifest = await loader.loadManifest()
    processManifestMetadata(manifest)

    await loader.loadInitial(3)

    chunkedContent.value = loader.getAssembledContent()
    mirrorDocument.value = {
      type: 'doc',
      content: chunkedContent.value,
    }
  }

  function processManifestMetadata(manifest: SectionManifest): void {
    const toc = manifest.toc || {}
    const meta = manifest.meta || {}

    const list_of: ListOfData = {
      figures: toc.list_of_figures || [],
      tables: toc.list_of_tables || [],
      examples: toc.list_of_examples || [],
    }

    documentMeta.value = {
      title: meta.title,
      subtitle: meta.subtitle,
      author: meta.author,
      pubdate: meta.pubdate,
      releaseinfo: meta.releaseinfo,
      copyright: meta.copyright,
      root_element: meta.root_element,
      cover: meta.cover,
      sections: toc.sections || [],
      numbering: convertNumbering(toc.numbering),
      index: toc.index || null,
      list_of: list_of,
    }
  }

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
        const list_of: ListOfData = {
          figures: data.list_of_figures || [],
          tables: data.list_of_tables || [],
          examples: data.list_of_examples || [],
        }
        documentMeta.value = {
          title: data.meta?.title,
          subtitle: data.meta?.subtitle,
          author: data.meta?.author,
          pubdate: data.meta?.pubdate,
          releaseinfo: data.meta?.releaseinfo,
          copyright: data.meta?.copyright,
          root_element: data.meta?.root_element,
          sections: data.toc.sections,
          numbering: data.toc.numbering || {},
          index: data.toc.index || null,
          list_of: list_of,
        }
      }
      return Promise.resolve()
    }

    // Standalone TOC data (without mirror content)
    if (data.toc) {
      const list_of: ListOfData = {
        figures: data.list_of_figures || [],
        tables: data.list_of_tables || [],
        examples: data.list_of_examples || [],
      }
      documentMeta.value = {
        sections: data.toc.sections || [],
        numbering: convertNumbering(data.toc.numbering),
        index: data.index || null,
        list_of: list_of,
      }
    }

    return Promise.resolve()
  }

  function loadFromWindow(): Promise<void> {
    loadError.value = null

    // Chunked format: load manifest + lazy sections
    const format = getOutputFormat()
    if (format === 'chunked') {
      return loadChunked().catch(err => {
        loadError.value = err instanceof Error ? err.message : 'Failed to load document'
      })
    }

    // Try inline data first (covers inline, dom, paged formats)
    const inlineData = (window as any).DOCBOOK_DATA
    if (inlineData && inlineData !== null) {
      return processDocbookData(inlineData)
    }

    // Try external data (dist format)
    if (format === 'dist') {
      const loader = createContentLoader()
      return loader.load().then(data => {
        if (data) return processDocbookData(data)
        loadError.value = 'No document data found'
        return Promise.resolve()
      }).catch(err => {
        loadError.value = err instanceof Error ? err.message : 'Failed to load document'
      })
    }

    // Try collection with inline data
    const collection = (window as any).DOCBOOK_COLLECTION
    if (collection && collection.books && collection.books.length > 0) {
      const firstBook = collection.books[0]
      if (firstBook.data) {
        return processDocbookData(firstBook.data)
      }
    }

    // Try async cache preload (dist format may have loaded from IDB)
    const cached = getCachedPreload()
    if (cached) {
      return processDocbookData(cached)
    }

    return fetch('docbook.data.json')
      .then(res => {
        if (!res.ok) throw new Error('Failed to load docbook.data.json')
        return res.json()
      })
      .then(data => processDocbookData(data))
      .catch(err => {
        console.error('Failed to load document data:', err)
        loadError.value = err instanceof Error ? err.message : 'Failed to load document'
      })
  }

  const title = computed(() => {
    if (documentMeta.value?.title) {
      return documentMeta.value.title
    }
    if (mirrorDocument.value?.attrs?.title) {
      return mirrorDocument.value.attrs.title
    }
    return 'DocBook Document'
  })
  const subtitle = computed(() => documentMeta.value?.subtitle || '')
  const author = computed(() => documentMeta.value?.author || '')
  const pubdate = computed(() => documentMeta.value?.pubdate || '')
  const copyright = computed(() => documentMeta.value?.copyright || '')
  const cover = computed(() => documentMeta.value?.cover || '')
  const sections = computed(() => documentMeta.value?.sections || [])
  const numbering = computed(() => documentMeta.value?.numbering || {})
  const index = computed(() => documentMeta.value?.index || null)
  const listOf = computed(() => documentMeta.value?.list_of || { figures: [], tables: [], examples: [] })

  function getNumbering(id: string): string {
    return numbering.value[id] || ''
  }

  return {
    documentMeta,
    mirrorDocument,
    isChunkedMode,
    loadError,
    loadFromWindow,
    loadChunkedSection,
    title,
    subtitle,
    author,
    pubdate,
    copyright,
    cover,
    sections,
    numbering,
    index,
    listOf,
    getNumbering
  }
})
