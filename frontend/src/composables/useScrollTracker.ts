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

      // Mark as read if any part of the section is visible in the viewport
      const isVisible = rect.bottom > containerRect.top && rect.top < containerRect.bottom
      if (isVisible) {
        ctx.readingStats.markSectionRead(section.id)
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
      ctx.readingStats.recordActivity()
      history.replaceState(null, '', `#${foundSection.id}`)
      saveScrollPosition(foundSection.id)
    }

    // Update scroll offset for current section periodically
    if (foundSection) {
      saveScrollOffset(foundSection.id)
    }
  }

  function saveScrollPosition(sectionId: string) {
    try {
      localStorage.setItem('docbook-position-' + ctx.documentStore.title, sectionId)
    } catch {}
  }

  function saveScrollOffset(sectionId: string) {
    const container = ctx.mainContent.value
    if (!container) return
    try {
      const el = document.getElementById(sectionId)
      if (!el) return
      const containerRect = container.getBoundingClientRect()
      const elTop = el.getBoundingClientRect().top - containerRect.top + container.scrollTop
      const offset = container.scrollTop - elTop
      localStorage.setItem('docbook-offset-' + ctx.documentStore.title, String(Math.round(offset)))
    } catch {}
  }

  function restoreScrollPosition(): boolean {
    try {
      const sectionId = localStorage.getItem('docbook-position-' + ctx.documentStore.title)
      if (!sectionId || !document.getElementById(sectionId)) return false

      const offsetStr = localStorage.getItem('docbook-offset-' + ctx.documentStore.title)
      const offset = offsetStr ? parseInt(offsetStr, 10) : 0

      const container = ctx.mainContent.value
      if (!container) return false

      const el = document.getElementById(sectionId)
      if (!el) return false

      const containerRect = container.getBoundingClientRect()
      const elTop = el.getBoundingClientRect().top - containerRect.top + container.scrollTop
      container.scrollTo({ top: elTop + offset })

      ctx.uiStore.setActiveSection(sectionId)
      return true
    } catch {
      return false
    }
  }

  return {
    readingProgress,
    showBackToTop,
    handleScroll,
    updateActiveSection,
    restoreScrollPosition,
  }
}
