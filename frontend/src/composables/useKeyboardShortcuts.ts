import type { Ref } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useEbookStore } from '@/composables/useEbookStore'

export interface KeyboardShortcutContext {
  showKeyboardHelp: Ref<boolean>
  ebookStore: ReturnType<typeof useEbookStore>
  uiStore: ReturnType<typeof useUiStore>
  documentStore: ReturnType<typeof useDocumentStore>
  sectionIds: Ref<string[]>
  navigateToId: (id: string) => void
  toggleRuler: () => void
  toggleBookmark: () => void
  ttsPlay: () => void
  ttsStop: () => void
  nextPage: () => void
  prevPage: () => void
}

export function useKeyboardShortcuts(ctx: KeyboardShortcutContext) {
  function handleGlobalKeydown(e: KeyboardEvent) {
    const inputFocused = isInputFocused()

    if (e.key === '/' && !inputFocused) {
      e.preventDefault()
      ctx.uiStore.openSearch()
    }

    if (e.key === 'Escape') {
      if (ctx.showKeyboardHelp.value) {
        ctx.showKeyboardHelp.value = false
        return
      }
      if (ctx.ebookStore.settingsOpen.value) {
        ctx.ebookStore.toggleSettings()
        return
      }
      if (ctx.uiStore.searchOpen) {
        ctx.uiStore.closeSearch()
        return
      }
      if (ctx.uiStore.sidebarOpen) {
        ctx.uiStore.closeSidebar()
        return
      }
    }

    if (inputFocused) return

    if (e.key === '?') {
      e.preventDefault()
      ctx.showKeyboardHelp.value = !ctx.showKeyboardHelp.value
      return
    }

    if (e.key === 's') {
      e.preventDefault()
      ctx.ebookStore.toggleSettings()
      return
    }

    if (e.key === 'f') {
      e.preventDefault()
      ctx.ebookStore.toggleFocusMode()
      return
    }

    if (e.key === 'r') {
      e.preventDefault()
      ctx.toggleRuler()
      return
    }

    if (e.key === 'b') {
      e.preventDefault()
      ctx.toggleBookmark()
      return
    }

    if (e.key === 'P') {
      e.preventDefault()
      ctx.ttsPlay()
      return
    }

    if (e.key === 'p') {
      e.preventDefault()
      ctx.ttsStop()
      return
    }

    if (e.key === 't') {
      e.preventDefault()
      ctx.uiStore.toggleSidebar()
      return
    }

    // j/k section navigation
    if (ctx.sectionIds.value.length > 0) {
      const current = ctx.sectionIds.value.indexOf(ctx.uiStore.activeSectionId || '')
      if (e.key === 'j' && current < ctx.sectionIds.value.length - 1) {
        e.preventDefault()
        ctx.navigateToId(ctx.sectionIds.value[current + 1])
      }
      if (e.key === 'k' && current > 0) {
        e.preventDefault()
        ctx.navigateToId(ctx.sectionIds.value[current - 1])
      }
    }

    // Paged mode navigation
    if (ctx.ebookStore.readingMode.value === 'paged') {
      if (e.key === 'ArrowRight' || e.key === ' ') {
        e.preventDefault()
        ctx.nextPage()
        return
      }
      if (e.key === 'ArrowLeft') {
        e.preventDefault()
        ctx.prevPage()
        return
      }
    }
  }

  return { handleGlobalKeydown }
}

function isInputFocused(): boolean {
  const active = document.activeElement
  return active instanceof HTMLInputElement || active instanceof HTMLTextAreaElement
}
