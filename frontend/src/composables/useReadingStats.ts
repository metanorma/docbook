import { ref, computed, onMounted, onUnmounted } from 'vue'

export interface ReadingStats {
  totalSections: number
  sectionsRead: Set<string>
  totalWords: number
  startTime: number
  activeReadingMs: number
  lastActiveAt: number
}

const STORAGE_KEY = 'docbook_reading_stats'
const ACTIVE_TIMEOUT = 30_000 // 30s of no activity = not reading
const SAVE_INTERVAL = 10_000

export function useReadingStats(docTitle: string, totalSections: number, sectionIds: string[]) {
  const sectionsRead = ref<Set<string>>(new Set())
  const totalWords = ref(0)
  const activeReadingMs = ref(0)
  const lastActiveAt = ref(Date.now())
  const startTime = ref(Date.now())
  let saveTimer: ReturnType<typeof setInterval> | null = null

  function storageKey(): string {
    return `${STORAGE_KEY}_${(docTitle || 'default').replace(/\s+/g, '_')}`
  }

  function load() {
    try {
      const stored = localStorage.getItem(storageKey())
      if (stored) {
        const data = JSON.parse(stored)
        sectionsRead.value = new Set(data.sectionsRead || [])
        activeReadingMs.value = data.activeReadingMs || 0
        startTime.value = data.startTime || Date.now()
      }
    } catch {}
  }

  function save() {
    try {
      localStorage.setItem(storageKey(), JSON.stringify({
        sectionsRead: [...sectionsRead.value],
        activeReadingMs: activeReadingMs.value,
        startTime: startTime.value,
      }))
    } catch {}
  }

  function markSectionRead(id: string) {
    if (!sectionsRead.value.has(id)) {
      sectionsRead.value = new Set([...sectionsRead.value, id])
    }
  }

  function recordActivity() {
    const now = Date.now()
    const gap = now - lastActiveAt.value
    if (gap < ACTIVE_TIMEOUT) {
      activeReadingMs.value += gap
    }
    lastActiveAt.value = now
  }

  function countWords() {
    const content = document.getElementById('main-content')
    if (!content) return
    totalWords.value = (content.textContent || '').split(/\s+/).filter(Boolean).length
  }

  const sectionsReadCount = computed(() => sectionsRead.value.size)
  const readPercentage = computed(() =>
    totalSections > 0 ? Math.round((sectionsRead.value.size / totalSections) * 100) : 0
  )
  const estimatedReadingTime = computed(() => {
    // Average reading speed: 200-250 words per minute
    const minutes = Math.ceil(totalWords.value / 225)
    return minutes
  })
  const activeReadingMinutes = computed(() =>
    Math.round(activeReadingMs.value / 60_000)
  )

  onMounted(() => {
    load()
    countWords()
    saveTimer = setInterval(save, SAVE_INTERVAL)
  })

  onUnmounted(() => {
    save()
    if (saveTimer) clearInterval(saveTimer)
  })

  function isSectionRead(id: string): boolean {
    return sectionsRead.value.has(id)
  }

  return {
    sectionsRead,
    sectionsReadCount,
    totalWords,
    readPercentage,
    estimatedReadingTime,
    activeReadingMinutes,
    totalSections,
    markSectionRead,
    recordActivity,
    isSectionRead,
  }
}
