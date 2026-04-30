import { ref, shallowRef, computed, watch, onMounted, onUnmounted, type Ref } from 'vue'

export interface LazySection {
  id: string
  visible: boolean
}

const ROOT_MARGIN = '5000px 0px'
const THRESHOLD = 0

// Progressive rendering: how many top-level blocks to render initially
const PROGRESSIVE_INITIAL = 20
const PROGRESSIVE_BATCH = 10

export function useLazySections(containerRef: Ref<HTMLElement | null>) {
  const visibleIds = ref<Set<string>>(new Set())
  const observer = shallowRef<IntersectionObserver | null>(null)
  const initialized = ref(false)

  // Progressive rendering: tracks how many top-level blocks are revealed
  const revealedCount = ref(PROGRESSIVE_INITIAL)
  const progressiveDone = ref(true) // true = all blocks revealed
  let totalBlockCount = 0

  function setTotalBlocks(count: number) {
    totalBlockCount = count
    revealedCount.value = count
    progressiveDone.value = true
  }

  function isProgressiveVisible(index: number): boolean {
    return index < revealedCount.value
  }

  // Use requestIdleCallback to progressively reveal more blocks
  let revealTimer: ReturnType<typeof setTimeout> | null = null

  function scheduleProgressiveReveal() {
    if (progressiveDone.value) return

    const reveal = () => {
      if (progressiveDone.value) return
      const remaining = totalBlockCount - revealedCount.value
      if (remaining <= 0) {
        progressiveDone.value = true
        return
      }
      revealedCount.value = Math.min(
        revealedCount.value + PROGRESSIVE_BATCH,
        totalBlockCount
      )
      if (revealedCount.value >= totalBlockCount) {
        progressiveDone.value = true
      } else {
        scheduleProgressiveReveal()
      }
    }

    if ('requestIdleCallback' in window) {
      requestIdleCallback(reveal, { timeout: 500 })
    } else {
      revealTimer = setTimeout(reveal, 100)
    }
  }

  function createObserver() {
    if (observer.value) return
    if (!containerRef.value) return

    observer.value = new IntersectionObserver(
      (entries) => {
        const updated = new Set(visibleIds.value)
        let changed = false
        for (const entry of entries) {
          const id = entry.target.id
          if (!id) continue
          // Grow-only: once visible, always visible.
          // Never un-render content that has already been shown.
          if (entry.isIntersecting) {
            if (!updated.has(id)) {
              updated.add(id)
              changed = true
            }
          }
        }
        if (changed) {
          visibleIds.value = updated
        }
      },
      {
        root: containerRef.value,
        rootMargin: ROOT_MARGIN,
        threshold: THRESHOLD,
      }
    )

    // Re-enable lazy mode after a frame so sections render first
    requestAnimationFrame(() => {
      initialized.value = true
    })
  }

  function observeSection(id: string) {
    if (!observer.value) return
    const el = document.getElementById(id)
    if (el && !el.dataset.lazyObserved) {
      el.dataset.lazyObserved = 'true'
      observer.value.observe(el)
      // If already in viewport (initial render), mark visible immediately
      if (containerRef.value) {
        const containerRect = containerRef.value.getBoundingClientRect()
        const elRect = el.getBoundingClientRect()
        const inView = elRect.top < containerRect.bottom + 2000 &&
                       elRect.bottom > containerRect.top - 2000
        if (inView) {
          visibleIds.value = new Set([...visibleIds.value, id])
        }
      }
    }
  }

  // Force a section to be visible immediately (used by navigation)
  function markVisible(id: string) {
    if (!id) return
    if (!visibleIds.value.has(id)) {
      visibleIds.value = new Set([...visibleIds.value, id])
    }
  }

  function unobserveAll() {
    if (observer.value) return
    observer.value.disconnect()
    document.querySelectorAll('[data-lazy-observed]').forEach(el => {
      delete (el as HTMLElement).dataset.lazyObserved
    })
  }

  function isVisible(id: string): boolean {
    if (!initialized.value) return true // Before init, render everything
    return visibleIds.value.has(id)
  }

  onMounted(() => {
    createObserver()
    // Mark first batch of sections visible, then enable lazy mode
    requestAnimationFrame(() => {
      initialized.value = true
    })
  })

  onUnmounted(() => {
    unobserveAll()
    if (revealTimer) clearTimeout(revealTimer)
    if (observer.value) {
      observer.value.disconnect()
      observer.value = null
    }
  })

  // Reset for a new document (e.g., switching library books)
  function reset() {
    unobserveAll()
    if (revealTimer) clearTimeout(revealTimer)
    if (observer.value) {
      observer.value.disconnect()
      observer.value = null
    }
    visibleIds.value = new Set()
    initialized.value = false
    revealedCount.value = PROGRESSIVE_INITIAL
    progressiveDone.value = true
    totalBlockCount = 0
  }

  return {
    visibleIds,
    isVisible,
    observeSection,
    markVisible,
    initialized,
    reset,
    createObserver,
    // Progressive rendering
    setTotalBlocks,
    isProgressiveVisible,
    revealedCount,
    progressiveDone,
  }
}
