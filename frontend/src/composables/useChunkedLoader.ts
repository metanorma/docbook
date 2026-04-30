// On-demand section loading with IndexedDB caching for chunked format.
//
// Loads a small manifest first (TOC + metadata), then lazy-loads
// per-section JSON files as the user scrolls. Sections are cached
// in IndexedDB so returning visitors skip network requests.

import { ref, shallowRef, type Ref } from 'vue'

export interface SectionManifest {
  meta: Record<string, any>
  toc: any
  total_sections: number
  section_ids: string[]
  version?: string
}

export interface SectionData {
  id: string
  content: any[]
  next: string | null
  prev: string | null
}

const DB_NAME = 'docbook_sections'
const STORE_NAME = 'sections'
const DB_VERSION = 1

class SectionCacheDB {
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
          const store = db.createObjectStore(STORE_NAME, { keyPath: 'cacheKey' })
          store.createIndex('docId', 'docId', { unique: false })
        }
      }
    })
  }

  async save(docId: string, sectionId: string, data: SectionData): Promise<void> {
    if (!this.db) return
    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(STORE_NAME, 'readwrite')
      const store = tx.objectStore(STORE_NAME)
      store.put({
        cacheKey: `${docId}/${sectionId}`,
        docId,
        sectionId,
        data,
        timestamp: Date.now(),
      })
      tx.oncomplete = () => resolve()
      tx.onerror = () => reject(tx.error)
    })
  }

  async load(docId: string, sectionId: string): Promise<SectionData | null> {
    if (!this.db) return null
    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(STORE_NAME, 'readonly')
      const store = tx.objectStore(STORE_NAME)
      const request = store.get(`${docId}/${sectionId}`)
      request.onsuccess = () => resolve(request.result?.data || null)
      request.onerror = () => reject(request.error)
    })
  }

  async clearForDoc(docId: string): Promise<void> {
    if (!this.db) return
    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(STORE_NAME, 'readwrite')
      const store = tx.objectStore(STORE_NAME)
      const index = store.index('docId')
      const request = index.openCursor(IDBKeyRange.only(docId))
      request.onsuccess = (event) => {
        const cursor = (event.target as IDBRequest).result
        if (cursor) {
          cursor.delete()
          cursor.continue()
        }
      }
      tx.oncomplete = () => resolve()
      tx.onerror = () => reject(tx.error)
    })
  }
}

let cacheDb: SectionCacheDB | null = null
let cacheDbUnavailable = false

async function getCacheDb(): Promise<SectionCacheDB | null> {
  if (cacheDbUnavailable) return null
  if (!cacheDb) {
    try {
      cacheDb = new SectionCacheDB()
      await cacheDb.init()
    } catch {
      cacheDbUnavailable = true
      return null
    }
  }
  return cacheDb
}

function getDocId(): string {
  return window.location.pathname
}

export function useChunkedLoader(containerRef?: Ref<HTMLElement | null>) {
  const manifest = shallowRef<SectionManifest | null>(null)
  const loadedSections = ref<Map<string, SectionData>>(new Map())
  const loadedIds = ref<Set<string>>(new Set())
  const pendingIds = ref<Set<string>>(new Set())
  const baseUrl = ref('')
  const allContentLoaded = ref(false)

  // IntersectionObserver for the sentinel element that triggers loading
  let sentinelObserver: IntersectionObserver | null = null
  let lastLoadedIndex = -1

  async function loadManifest(): Promise<SectionManifest> {
    const manifestUrl = (window as any).DOCBOOK_MANIFEST || 'manifest.json'
    baseUrl.value = manifestUrl.replace(/manifest\.json$/, '')

    const res = await fetch(baseUrl.value + 'manifest.json')
    if (!res.ok) throw new Error(`Failed to load manifest: ${res.status}`)
    const data: SectionManifest = await res.json()
    manifest.value = data

    // Invalidate cache if manifest version changed
    if (data.version) {
      const db = await getCacheDb()
      if (db) {
        const cachedVersion = localStorage.getItem('docbook-manifest-version-' + getDocId())
        if (cachedVersion && cachedVersion !== data.version) {
          await clearCachedSections()
        }
        localStorage.setItem('docbook-manifest-version-' + getDocId(), data.version)
      }
    }

    return data
  }

  async function clearCachedSections(): Promise<void> {
    const db = await getCacheDb()
    if (!db) return
    // Clear sections via the public clear method
    try {
      const dbImpl = db as SectionCacheDB
      await dbImpl.clearForDoc(getDocId())
    } catch {}
  }

  async function loadSection(sectionId: string, useCache = true): Promise<SectionData | null> {
    if (!sectionId) return null
    if (loadedIds.value.has(sectionId)) {
      return loadedSections.value.get(sectionId) || null
    }
    if (pendingIds.value.has(sectionId)) return null

    pendingIds.value = new Set([...pendingIds.value, sectionId])

    try {
      const db = await getCacheDb()
      const docId = getDocId()

      if (useCache && db) {
        try {
          const cached = await db.load(docId, sectionId)
          if (cached) {
            loadedSections.value = new Map([...loadedSections.value, [sectionId, cached]])
            loadedIds.value = new Set([...loadedIds.value, sectionId])
            return cached
          }
        } catch {
          // Cache read failed, fall through to network
        }
      }

      const url = `${baseUrl.value}sections/${sectionId}.json`
      const res = await fetch(url)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data: SectionData = await res.json()

      if (db) {
        try {
          await db.save(docId, sectionId, data)
        } catch {
          // Cache write failed, non-critical
        }
      }

      loadedSections.value = new Map([...loadedSections.value, [sectionId, data]])
      loadedIds.value = new Set([...loadedIds.value, sectionId])
      return data
    } catch (e) {
      console.error(`Failed to load section ${sectionId}:`, e)
      return null
    } finally {
      const updated = new Set(pendingIds.value)
      updated.delete(sectionId)
      pendingIds.value = updated
    }
  }

  // Load initial sections (enough to fill viewport) + prefetch nearby
  async function loadInitial(initialCount = 3): Promise<void> {
    if (!manifest.value) return
    const ids = manifest.value.section_ids

    // Load first N sections sequentially
    for (let i = 0; i < Math.min(initialCount, ids.length); i++) {
      const data = await loadSection(ids[i])
      if (data) lastLoadedIndex = i
    }

    // Prefetch next batch
    prefetchAhead(initialCount, initialCount + 2)
  }

  // Load the next section (called when sentinel becomes visible)
  async function loadNext(): Promise<void> {
    if (!manifest.value) return
    const ids = manifest.value.section_ids
    const nextIndex = lastLoadedIndex + 1
    if (nextIndex >= ids.length) {
      allContentLoaded.value = true
      return
    }

    const data = await loadSection(ids[nextIndex])
    if (data) {
      lastLoadedIndex = nextIndex
      prefetchAhead(nextIndex + 1, 2)
      if (nextIndex >= ids.length - 1) {
        allContentLoaded.value = true
      }
    }
  }

  // Prefetch sections ahead of current position (background, no await)
  function prefetchAhead(startIndex: number, count: number): void {
    if (!manifest.value) return
    const ids = manifest.value.section_ids
    for (let i = startIndex; i < Math.min(startIndex + count, ids.length); i++) {
      if (!loadedIds.value.has(ids[i]) && !pendingIds.value.has(ids[i])) {
        loadSection(ids[i])
      }
    }
  }

  // Build the assembled content array for MirrorRenderer
  function getAssembledContent(): any[] {
    if (!manifest.value) return []
    const blocks: any[] = []
    for (const id of manifest.value.section_ids) {
      const section = loadedSections.value.get(id)
      if (section) {
        blocks.push(...section.content)
      }
    }
    return blocks
  }

  // Set up IntersectionObserver on a sentinel element
  function setupSentinelObserver(): void {
    if (sentinelObserver) return
    if (!containerRef?.value) return

    sentinelObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && !allContentLoaded.value) {
            loadNext()
          }
        }
      },
      {
        root: containerRef.value,
        rootMargin: '1000px 0px',
        threshold: 0,
      }
    )
  }

  function observeSentinel(el: HTMLElement): void {
    if (!sentinelObserver) setupSentinelObserver()
    sentinelObserver?.observe(el)
  }

  function unobserveSentinel(el: HTMLElement): void {
    sentinelObserver?.unobserve(el)
  }

  function reset(): void {
    if (sentinelObserver) {
      sentinelObserver.disconnect()
      sentinelObserver = null
    }
    loadedSections.value = new Map()
    loadedIds.value = new Set()
    pendingIds.value = new Set()
    manifest.value = null
    lastLoadedIndex = -1
    allContentLoaded.value = false
  }

  return {
    manifest,
    loadedSections,
    loadedIds,
    pendingIds,
    allContentLoaded,
    loadManifest,
    loadInitial,
    loadNext,
    loadSection,
    prefetchAhead,
    getAssembledContent,
    setupSentinelObserver,
    observeSentinel,
    unobserveSentinel,
    reset,
  }
}
