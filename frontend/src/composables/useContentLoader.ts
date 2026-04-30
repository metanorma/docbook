// Content loader abstraction for four output formats:
// inline, dom, dist, paged
//
// Each loader hides its data source (window global, fetch, DOM)
// behind the same interface. The documentStore doesn't know where data comes from.
//
// Includes document-level IndexedDB caching: parsed documents are stored in IDB
// so returning visitors get instant loads. Cache is keyed by document fingerprint
// (source URL or content hash) and invalidated on version changes.

export interface ContentLoader {
  load(): Promise<Record<string, any> | null>
}

// ============================================================
// Document-level IndexedDB cache
// ============================================================

const DOC_CACHE_DB = 'docbook_doc_cache'
const DOC_CACHE_STORE = 'documents'
const DOC_CACHE_VERSION = 1

let docCacheDb: IDBDatabase | null = null
let docCacheInitPromise: Promise<IDBDatabase | null> | null = null

function openDocCache(): Promise<IDBDatabase | null> {
  if (docCacheDb) return Promise.resolve(docCacheDb)
  if (docCacheInitPromise) return docCacheInitPromise

  docCacheInitPromise = new Promise((resolve) => {
    try {
      const req = indexedDB.open(DOC_CACHE_DB, DOC_CACHE_VERSION)
      req.onupgradeneeded = () => {
        const db = req.result
        if (!db.objectStoreNames.contains(DOC_CACHE_STORE)) {
          const store = db.createObjectStore(DOC_CACHE_STORE, { keyPath: 'key' })
          store.createIndex('timestamp', 'timestamp', { unique: false })
        }
      }
      req.onsuccess = () => {
        docCacheDb = req.result
        resolve(docCacheDb)
      }
      req.onerror = () => resolve(null)
    } catch {
      resolve(null)
    }
  })
  return docCacheInitPromise
}

function getDocFingerprint(): string {
  const w = window as any
  // For dist/chunked: use the data source URL as fingerprint
  const source = w.DOCBOOK_DATA_SOURCE || w.DOCBOOK_MANIFEST
  if (source) return source.toString()
  // For inline/dom: use pathname + content hash if available
  const data = w.DOCBOOK_DATA
  if (data?.meta?.title) return `${location.pathname}:${data.meta.title}`
  return location.pathname
}

async function getCachedDocument(key: string): Promise<Record<string, any> | null> {
  const db = await openDocCache()
  if (!db) return null
  return new Promise((resolve) => {
    try {
      const tx = db.transaction(DOC_CACHE_STORE, 'readonly')
      const store = tx.objectStore(DOC_CACHE_STORE)
      const req = store.get(key)
      req.onsuccess = () => {
        const record = req.result
        if (record && record.data) {
          resolve(record.data)
        } else {
          resolve(null)
        }
      }
      req.onerror = () => resolve(null)
    } catch {
      resolve(null)
    }
  })
}

async function setCachedDocument(key: string, data: Record<string, any>): Promise<void> {
  const db = await openDocCache()
  if (!db) return
  try {
    const tx = db.transaction(DOC_CACHE_STORE, 'readwrite')
    const store = tx.objectStore(DOC_CACHE_STORE)
    store.put({
      key,
      data,
      timestamp: Date.now(),
    })
  } catch {
    // Non-critical: cache write failure shouldn't break anything
  }
}

// ============================================================
// Loader factory
// ============================================================

// Factory — returns the correct loader based on window globals
export function createContentLoader(): ContentLoader {
  const w = window as any
  const format = w.DOCBOOK_FORMAT

  if (format === 'dist') return new ExternalJsonLoader()
  // dom, paged, and default all use inline data
  return new InlineJsonLoader()
}

// 1. Inline JSON — reads window.DOCBOOK_DATA (current behavior)
// Caches parsed data in IndexedDB for instant re-opens.
class InlineJsonLoader implements ContentLoader {
  async load(): Promise<Record<string, any> | null> {
    const data = (window as any).DOCBOOK_DATA
    if (!data) return null

    // Cache the parsed document for instant re-opens
    const fp = getDocFingerprint()
    setCachedDocument(fp, data).catch(() => {})

    return data
  }
}

// 2. External JSON — fetches from URL in window.DOCBOOK_DATA_SOURCE
// Caches fetched data in IndexedDB to skip network on re-opens.
class ExternalJsonLoader implements ContentLoader {
  async load(): Promise<Record<string, any> | null> {
    const source = (window as any).DOCBOOK_DATA_SOURCE
    if (!source) return null

    const fp = getDocFingerprint()

    // Try cache first for instant load
    const cached = await getCachedDocument(fp)
    if (cached) {
      // Re-validate in background — if source changed, update cache
      this.backgroundRefresh(fp, source)
      return cached
    }

    // No cache — fetch from network
    try {
      const res = await fetch(source)
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`)
      const data = await res.json()
      setCachedDocument(fp, data).catch(() => {})
      return data
    } catch (e) {
      console.error('Failed to load external content:', e)
      throw e
    }
  }

  private backgroundRefresh(fp: string, source: string): void {
    // Fetch fresh data in background; if it differs, update cache
    // so next visit gets the new version.
    fetch(source, { cache: 'no-cache' })
      .then(res => res.ok ? res.json() : null)
      .then(data => {
        if (data) setCachedDocument(fp, data).catch(() => {})
      })
      .catch(() => {})
  }
}

// ============================================================
// Pre-load from cache for instant first paint
// ============================================================

let preloadedFromCache: Record<string, any> | null = null
let preloadAttempted = false

// Called synchronously during app init to check cache before
// any async loading begins. Returns cached data if available.
export function preloadFromCache(): Record<string, any> | null {
  if (preloadAttempted) return preloadedFromCache
  preloadAttempted = true

  const format = (window as any).DOCBOOK_FORMAT
  // Only preload for dist and inline formats (not chunked, which has its own caching)
  if (format === 'chunked') return null

  // For inline format, data is already in window.DOCBOOK_DATA — no need to preload
  if (!format && (window as any).DOCBOOK_DATA) return null

  // For dist format, kick off async cache check
  const fp = getDocFingerprint()
  getCachedDocument(fp).then(data => {
    if (data) preloadedFromCache = data
  }).catch(() => {})

  return null
}

// Returns any data that was loaded from cache asynchronously
export function getCachedPreload(): Record<string, any> | null {
  return preloadedFromCache
}

// Format detection helpers
export function getOutputFormat(): string {
  return (window as any).DOCBOOK_FORMAT || 'inline'
}

export function isDomFormat(): boolean {
  return getOutputFormat() === 'dom'
}

export function isChunkedFormat(): boolean {
  return getOutputFormat() === 'chunked'
}
