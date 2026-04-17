import FlexSearch from 'flexsearch'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'

interface SearchResult {
  id: string
  title: string
  type: string
}

export type { SearchResult }

const DB_NAME = 'docbook_search'
const STORE_NAME = 'index'
const DB_VERSION = 1

class SearchIndexDB {
  private db: IDBDatabase | null = null

  async init(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION)

      request.onerror = () => reject(request.error)

      request.onsuccess = () => {
        this.db = request.result
        resolve()
      }

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME, { keyPath: 'docId' })
        }
      }
    })
  }

  async saveIndex(docId: string, data: unknown): Promise<void> {
    if (!this.db) return
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(STORE_NAME, 'readwrite')
      const store = tx.objectStore(STORE_NAME)
      const request = store.put({ docId, data, timestamp: Date.now() })
      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  async loadIndex(docId: string): Promise<unknown | null> {
    if (!this.db) return null
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(STORE_NAME, 'readonly')
      const store = tx.objectStore(STORE_NAME)
      const request = store.get(docId)
      request.onsuccess = () => resolve(request.result?.data || null)
      request.onerror = () => reject(request.error)
    })
  }

  async clear(): Promise<void> {
    if (!this.db) return
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(STORE_NAME, 'readwrite')
      const store = tx.objectStore(STORE_NAME)
      const request = store.clear()
      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }
}

let searchDb: SearchIndexDB | null = null

async function getSearchDb(): Promise<SearchIndexDB> {
  if (!searchDb) {
    searchDb = new SearchIndexDB()
    await searchDb.init()
  }
  return searchDb
}

export function useSearch() {
  const documentStore = useDocumentStore()

  const query = ref('')
  const results = ref<SearchResult[]>([])
  const isSearching = ref(false)
  const isIndexed = ref(false)
  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  // FlexSearch Document index for TOC items
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let index: any = new (FlexSearch as any).Document({
    document: {
      id: 'id',
      index: ['title'],
      store: ['id', 'title', 'type']
    },
    tokenize: 'forward',
    resolution: 9
  })

  // Serialize index for IndexedDB storage
  function serializeIndex(): string {
    return index.export()
  }

  // Load index from IndexedDB
  async function loadFromDb(): Promise<boolean> {
    try {
      const db = await getSearchDb()
      const docId = window.location.pathname + '-' + (documentStore.title || 'default')
      const data = await db.loadIndex(docId)
      if (data) {
        index = new (FlexSearch as any).Document({
          document: {
            id: 'id',
            index: ['title'],
            store: ['id', 'title', 'type']
          },
          tokenize: 'forward',
          resolution: 9
        })
        index.import(data)
        isIndexed.value = true
        return true
      }
    } catch (e) {
      console.warn('Failed to load search index from IndexedDB:', e)
    }
    return false
  }

  // Save index to IndexedDB
  async function saveToDb() {
    try {
      const db = await getSearchDb()
      const docId = window.location.pathname + '-' + (documentStore.title || 'default')
      await db.saveIndex(docId, serializeIndex())
    } catch (e) {
      console.warn('Failed to save search index to IndexedDB:', e)
    }
  }

  function buildIndexes() {
    index.clear()
    addToIndex(documentStore.sections)
    saveToDb() // Persist to IndexedDB
    isIndexed.value = true
  }

  function addToIndex(items: TocItem[]) {
    items.forEach(item => {
      index.add({
        id: item.id,
        title: item.title,
        type: item.type
      })
      if (item.children && item.children.length > 0) {
        addToIndex(item.children)
      }
    })
  }

  function search() {
    if (!query.value.trim()) {
      results.value = []
      return
    }

    isSearching.value = true

    const searchResults = index.search(query.value, { limit: 30, enrich: true })

    const combined: SearchResult[] = []
    const seen = new Set<string>()

    if (Array.isArray(searchResults)) {
      searchResults.forEach((field: { result: Array<{ id: string; doc?: SearchResult }> }) => {
        if (field.result && Array.isArray(field.result)) {
          field.result.forEach((r: { id: string; doc?: SearchResult }) => {
            if (r.doc && !seen.has(r.id)) {
              seen.add(r.id)
              combined.push(r.doc)
            }
          })
        }
      })
    }

    results.value = combined.slice(0, 50)
    isSearching.value = false
  }

  function debouncedSearch() {
    if (debounceTimer) clearTimeout(debounceTimer)
    debounceTimer = setTimeout(search, 150)
  }

  watch(query, debouncedSearch)

  // Watch for document data changes to rebuild indexes
  watch(
    () => documentStore.mirrorDocument,
    async () => {
      // Try loading from IndexedDB first
      const loaded = await loadFromDb()
      if (!loaded) {
        // Defer index building to after page load to avoid blocking
        if ('requestIdleCallback' in window) {
          requestIdleCallback(() => buildIndexes(), { timeout: 2000 })
        } else {
          setTimeout(buildIndexes, 100)
        }
      }
    },
    { immediate: true }
  )

  function selectResult(result: SearchResult) {
    // Scroll to section and close search
    const element = document.getElementById(result.id)
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' })
      closeSearch()
    }
  }

  function closeSearch() {
    query.value = ''
    results.value = []
  }

  function rebuildIndex() {
    buildIndexes()
  }

  return {
    query,
    results,
    isSearching,
    isIndexed,
    search,
    selectResult,
    closeSearch,
    rebuildIndex
  }
}
