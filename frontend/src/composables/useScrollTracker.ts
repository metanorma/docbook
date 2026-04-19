import { ref, type Ref } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useReadingStats } from '@/composables/useReadingStats'

export interface ScrollTrackerContext {
  mainContent: Ref<HTMLElement | null>
  documentStore: ReturnType<typeof useDocumentStore>
  uiStore: ReturnType<typeof useUiStore>
  readingStats: ReturnType<typeof useReadingStats>
}

export function useScrollTracker(ctx: ScrollTrackerContext) {
  const readingProgress = ref(0)
  const showBackToTop = ref(false)
  let scrollTimeout: ReturnType<typeof setTimeout> | null = null

  function handleScroll() {
    const container = ctx.mainContent.value
    if (container) {
      const scrollable = container.scrollHeight - container.clientHeight
      readingProgress.value = scrollable > 0 ? Math.min(100, Math.max(0, (container.scrollTop / scrollable) * 100)) : 0
      showBackToTop.value = container.scrollTop > container.clientHeight * 3
    }

    if (scrollTimeout) clearTimeout(scrollTimeout)
    scrollTimeout = setTimeout(() => {
      updateActiveSection()
    }, 50)
  }

  function updateActiveSection() {
    if (!ctx.mainContent.value) return

    const container = ctx.mainContent.value
    const containerRect = container.getBoundingClientRect()
    const scrollTop = container.scrollTop
    const sections = ctx.documentStore.sections

    let foundSection: TocItem | null = null

    function checkSection(section: TocItem) {
      const element = document.getElementById(section.id)
      if (!element) return

      const rect = element.getBoundingClientRect()
      const elementScrollTop = rect.top - containerRect.top + scrollTop

      if (elementScrollTop <= scrollTop + 200) {
        foundSection = section
      }
    }

    function walkSections(sects: TocItem[]) {
      for (const sect of sects) {
        checkSection(sect)
        if (sect.children) {
          walkSections(sect.children)
        }
      }
    }

    walkSections(sections)

    if (foundSection && foundSection.id !== ctx.uiStore.activeSectionId) {
      ctx.uiStore.setActiveSection(foundSection.id)
      ctx.readingStats.markSectionRead(foundSection.id)
      ctx.readingStats.recordActivity()
      history.replaceState(null, '', `#${foundSection.id}`)
      try {
        localStorage.setItem('docbook-position-' + ctx.documentStore.title, foundSection.id)
      } catch {}
    }
  }

  return {
    readingProgress,
    showBackToTop,
    handleScroll,
    updateActiveSection,
  }
}
