import { ref, shallowRef, onMounted, onUnmounted, type Ref } from 'vue'

export interface LazySection {
  id: string
  visible: boolean
}

const ROOT_MARGIN = '2000px 0px'
const THRESHOLD = 0

export function useLazySections(containerRef: Ref<HTMLElement | null>) {
  const visibleIds = ref<Set<string>>(new Set())
  const observer = shallowRef<IntersectionObserver | null>(null)
  const initialized = ref(false)

  function createObserver() {
    if (observer.value) return

    observer.value = new IntersectionObserver(
      (entries) => {
        const updated = new Set(visibleIds.value)
        let changed = false
        for (const entry of entries) {
          const id = entry.target.id
          if (!id) continue
          if (entry.isIntersecting) {
            if (!updated.has(id)) {
              updated.add(id)
              changed = true
            }
          } else {
            if (updated.has(id)) {
              updated.delete(id)
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

  function unobserveAll() {
    if (!observer.value) return
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
    if (observer.value) {
      observer.value.disconnect()
      observer.value = null
    }
  })

  return {
    visibleIds,
    isVisible,
    observeSection,
    initialized,
  }
}
