import { ref, computed } from 'vue'

export interface SyncData {
  bookmarks: Array<{ sectionId: string; title: string; snippet: string }>
  readingPosition: string | null
  settings: Record<string, any>
  stats: { sectionsRead: string[]; activeReadingMs: number }
  updatedAt: number
}

export interface SyncBackend {
  name: string
  save(data: SyncData): Promise<void>
  load(): Promise<SyncData | null>
}

// localStorage-based sync backend (for demo/single-device use)
class LocalStorageBackend implements SyncBackend {
  name = 'local'
  private key: string

  constructor(docTitle: string) {
    this.key = `docbook_sync_${(docTitle || 'default').replace(/\s+/g, '_')}`
  }

  async save(data: SyncData): Promise<void> {
    localStorage.setItem(this.key, JSON.stringify(data))
  }

  async load(): Promise<SyncData | null> {
    const stored = localStorage.getItem(this.key)
    return stored ? JSON.parse(stored) : null
  }
}

export function useCloudSync(docTitle: string) {
  const syncing = ref(false)
  const lastSyncAt = ref<number | null>(null)
  const syncError = ref<string | null>(null)
  const backend = ref<SyncBackend>(new LocalStorageBackend(docTitle))

  function setBackend(b: SyncBackend) {
    backend.value = b
  }

  async function exportSyncData(): Promise<SyncData> {
    // Gather data from localStorage
    const docKey = (docTitle || 'default').replace(/\s+/g, '_')

    let bookmarks: SyncData['bookmarks'] = []
    try {
      const stored = localStorage.getItem(`docbook_bookmarks_${docKey}`)
      if (stored) {
        bookmarks = JSON.parse(stored).map((b: any) => ({
          sectionId: b.sectionId,
          title: b.title,
          snippet: b.snippet || '',
        }))
      }
    } catch {}

    let readingPosition: string | null = null
    try {
      readingPosition = localStorage.getItem(`docbook-position-${docTitle}`)
    } catch {}

    let settings: Record<string, any> = {}
    try {
      const stored = localStorage.getItem('docbook_ebook_preferences')
      if (stored) settings = JSON.parse(stored)
    } catch {}

    let stats: SyncData['stats'] = { sectionsRead: [], activeReadingMs: 0 }
    try {
      const stored = localStorage.getItem(`docbook_reading_stats_${docKey}`)
      if (stored) {
        const data = JSON.parse(stored)
        stats = {
          sectionsRead: data.sectionsRead || [],
          activeReadingMs: data.activeReadingMs || 0,
        }
      }
    } catch {}

    return {
      bookmarks,
      readingPosition,
      settings,
      stats,
      updatedAt: Date.now(),
    }
  }

  async function importSyncData(data: SyncData): Promise<void> {
    const docKey = (docTitle || 'default').replace(/\s+/g, '_')

    // Restore bookmarks
    if (data.bookmarks.length > 0) {
      const bookmarksData = data.bookmarks.map((b, i) => ({
        id: `bm_${Date.now()}_${i}`,
        sectionId: b.sectionId,
        title: b.title,
        snippet: b.snippet || '',
        createdAt: data.updatedAt,
      }))
      localStorage.setItem(`docbook_bookmarks_${docKey}`, JSON.stringify(bookmarksData))
    }

    // Restore reading position
    if (data.readingPosition) {
      localStorage.setItem(`docbook-position-${docTitle}`, data.readingPosition)
    }

    // Restore settings
    if (Object.keys(data.settings).length > 0) {
      localStorage.setItem('docbook_ebook_preferences', JSON.stringify(data.settings))
    }

    // Restore stats
    if (data.stats.sectionsRead.length > 0) {
      localStorage.setItem(`docbook_reading_stats_${docKey}`, JSON.stringify({
        sectionsRead: data.stats.sectionsRead,
        activeReadingMs: data.stats.activeReadingMs,
        startTime: Date.now(),
      }))
    }
  }

  async function push(): Promise<void> {
    syncing.value = true
    syncError.value = null
    try {
      const data = await exportSyncData()
      await backend.value.save(data)
      lastSyncAt.value = Date.now()
    } catch (e: any) {
      syncError.value = e.message || 'Sync failed'
    } finally {
      syncing.value = false
    }
  }

  async function pull(): Promise<void> {
    syncing.value = true
    syncError.value = null
    try {
      const data = await backend.value.load()
      if (data) {
        await importSyncData(data)
        lastSyncAt.value = data.updatedAt
      }
    } catch (e: any) {
      syncError.value = e.message || 'Sync failed'
    } finally {
      syncing.value = false
    }
  }

  const backendName = computed(() => backend.value.name)

  return {
    syncing,
    lastSyncAt,
    syncError,
    backendName,
    setBackend,
    push,
    pull,
    exportSyncData,
    importSyncData,
  }
}
