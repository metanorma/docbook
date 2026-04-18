import { ref, computed, watch, onMounted, onUnmounted, type Ref } from 'vue'

export function usePaginatedMode(containerRef: Ref<HTMLElement | null>) {
  const currentPage = ref(1)
  const totalPages = ref(1)
  const pageHeight = ref(0)

  function calculatePages() {
    const container = containerRef.value
    if (!container) return

    const viewportHeight = container.clientHeight
    if (viewportHeight <= 0) return

    pageHeight.value = viewportHeight

    const scrollHeight = container.scrollHeight
    totalPages.value = Math.max(1, Math.ceil(scrollHeight / viewportHeight))

    // Clamp current page
    if (currentPage.value > totalPages.value) {
      currentPage.value = totalPages.value
    }
  }

  function goToPage(page: number) {
    const container = containerRef.value
    if (!container) return

    const target = Math.max(1, Math.min(page, totalPages.value))
    currentPage.value = target
    container.scrollTo({
      top: (target - 1) * pageHeight.value,
      behavior: 'smooth'
    })
  }

  function nextPage() {
    if (currentPage.value < totalPages.value) {
      goToPage(currentPage.value + 1)
    }
  }

  function prevPage() {
    if (currentPage.value > 1) {
      goToPage(currentPage.value - 1)
    }
  }

  // Track current page from scroll position
  let scrollTimer: ReturnType<typeof setTimeout> | null = null
  function handleScroll() {
    if (scrollTimer) clearTimeout(scrollTimer)
    scrollTimer = setTimeout(() => {
      const container = containerRef.value
      if (!container || pageHeight.value <= 0) return
      currentPage.value = Math.max(1, Math.min(
        Math.floor(container.scrollTop / pageHeight.value) + 1,
        totalPages.value
      ))
    }, 50)
  }

  // Recalculate on resize
  let resizeObserver: ResizeObserver | null = null

  onMounted(() => {
    const container = containerRef.value
    if (!container) return

    resizeObserver = new ResizeObserver(() => {
      calculatePages()
    })
    resizeObserver.observe(container)
  })

  onUnmounted(() => {
    if (resizeObserver) {
      resizeObserver.disconnect()
      resizeObserver = null
    }
    if (scrollTimer) clearTimeout(scrollTimer)
  })

  const progress = computed(() =>
    totalPages.value > 1 ? ((currentPage.value - 1) / (totalPages.value - 1)) * 100 : 0
  )

  return {
    currentPage,
    totalPages,
    pageHeight,
    progress,
    calculatePages,
    goToPage,
    nextPage,
    prevPage,
    handleScroll,
  }
}
