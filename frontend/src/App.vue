<template>
  <EbookContainer :class="['h-screen overflow-hidden', ebookStore.getThemeClass()]" :style="ebookStore.getCssVariables()">
    <!-- Skip to content (accessibility) -->
    <!-- Library Index (collection mode) -->
    <div v-if="showLibraryIndex" class="library-index-wrapper" :class="{ dark: isLibraryDark }">
      <LibraryIndex @open-book="onLibraryBookOpened" />
    </div>

    <!-- Single book / Library book reader -->
    <template v-else>
    <a href="#main-content" class="skip-link" @click.prevent="skipToContent">Skip to content</a>

    <!-- Reading progress bar -->
    <ReadingProgressBar :progress="readingProgress" :visible="ebookStore.showProgress.value" />

    <!-- Mobile overlay -->
    <div
      v-if="uiStore.sidebarOpen"
      @click="handleOverlayClick"
      class="fixed inset-0 bg-black/50 z-40"
      :class="{ 'lg:hidden': !ebookStore.focusMode.value }"
    ></div>

    <AppSidebar v-show="!ebookStore.focusMode.value || uiStore.sidebarOpen" />

    <!-- Ebook Top Bar -->
    <div :class="['focus-mode-topbar', { 'focus-mode-topbar--hidden': ebookStore.focusMode.value && !uiStore.sidebarOpen && !focusRevealTopbar, 'focus-mode-topbar--reveal': (ebookStore.focusMode.value && focusRevealTopbar) || (ebookStore.focusMode.value && uiStore.sidebarOpen) }]">
      <EbookTopBar
        :title="documentStore.title"
        :sidebar-open="uiStore.sidebarOpen"
        :show-back-to-library="isLibraryMode"
        @toggle-toc="toggleToc"
        @toggle-settings="ebookStore.toggleSettings"
        @back-to-library="backToLibrary"
      />
    </div>

    <!-- Focus mode indicator -->
    <button
      v-if="ebookStore.focusMode.value && !uiStore.sidebarOpen"
      @click="exitFocusMode"
      class="focus-mode-indicator"
      title="Exit focus mode (f)"
    >
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"/></svg>
      Focus mode
    </button>

    <!-- TTS indicator -->
    <div v-if="tts.speaking.value" class="tts-indicator">
      <button @click="tts.speak()" class="tts-btn" :title="tts.paused.value ? 'Resume' : 'Pause'">
        <svg v-if="tts.paused.value" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/></svg>
        <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      </button>
      <span class="tts-label">{{ tts.paused.value ? 'Paused' : 'Speaking...' }}</span>
      <button @click="tts.stop()" class="tts-btn" title="Stop">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 10a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z"/></svg>
      </button>
    </div>

    <main ref="mainContent" id="main-content" role="main" :class="[
      'h-screen overflow-y-auto transition-all duration-200',
      !ebookStore.focusMode.value ? 'pt-14' : 'pt-0',
      uiStore.sidebarOpen ? 'lg:pl-[280px]' : '',
      ebookStore.readingMode.value === 'paged' ? 'paged-mode' : ''
    ]" @scroll="onScroll">
      <!-- Active section breadcrumb -->
      <BreadcrumbBar v-if="ancestorChain.length > 0 && !ebookStore.focusMode.value" :ancestor-chain="ancestorChain" />

      <div class="px-6 py-10 lg:px-8 lg:py-12 mx-auto transition-[max-width] duration-300 ease-out" :style="contentStyle">
        <!-- Title page -->
        <TitlePage
          v-if="documentStore.title && documentStore.title !== 'DocBook Document'"
          :title="documentStore.title"
          :subtitle="documentStore.subtitle"
          :author="documentStore.author"
          :pubdate="documentStore.pubdate"
          :copyright="documentStore.copyright"
        />

        <!-- DocbookMirror format (ProseMirror-style) -->
        <div v-if="useDomContent" id="docbook-content" class="db-content">
          <!-- DOM format: content is pre-rendered by Ruby HtmlRenderer, already in #docbook-content -->
        </div>
        <div v-else-if="documentStore.mirrorDocument" class="db-content">
          <!-- Reference card swiper mode -->
          <RefCardSwiper
            v-if="ebookStore.refCardMode.value && refEntries.length > 0"
            :entries="refEntries"
          />
          <!-- Default mirror renderer -->
          <MirrorRenderer v-else :blocks="documentStore.mirrorDocument.content || []" />

          <!-- Lists of figures/tables/examples -->
          <ListOfSection
            v-if="hasLists"
            :list-of="documentStore.listOf"
          />
        </div>

        <!-- Footer -->
        <footer class="app-footer mt-16 pt-8 border-t text-center text-sm">
          Generated by <a href="https://github.com/metanorma/metanorma-docbook" class="app-footer-link hover:underline">Metanorma Docbook</a> gem
        </footer>
      </div>
    </main>

    <SearchModal />
    <SettingsPanel />
    <ImageLightbox
      :visible="lightbox.visible"
      :src="lightbox.src"
      :alt="lightbox.alt"
      :title="lightbox.title"
      @close="lightbox.visible = false"
    />

    <!-- Keyboard help overlay -->
    <KeyboardHelp :visible="showKeyboardHelp" @close="showKeyboardHelp = false" />

    <!-- Section prev/next navigation -->
    <SectionNav
      :section-ids="sectionIds"
      :active-index="activeSectionIndex"
      :visible="showSectionNav"
      @navigate="navigateToId"
    />

    <!-- Back to top -->
    <Transition name="back-to-top-fade">
      <button v-if="showBackToTop" class="back-to-top" @click="scrollToTop" title="Back to top">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/>
        </svg>
      </button>
    </Transition>

    <!-- Screen reader announcements -->
    <div role="status" aria-live="polite" aria-atomic="true" class="sr-only">{{ sectionAnnouncement }}</div>

    <!-- Page navigation for paged mode -->
    <div v-if="ebookStore.readingMode.value === 'paged'" class="page-nav">
      <button @click="prevPage" :disabled="currentPage <= 1" class="page-nav-btn" title="Previous page">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
      </button>
      <span class="page-nav-info">{{ currentPage }} / {{ totalPages }}</span>
      <button @click="nextPage" :disabled="currentPage >= totalPages" class="page-nav-btn" title="Next page">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
      </button>
    </div>

    <!-- Reading ruler -->
    <div
      v-if="rulerEnabled && rulerY >= 0"
      class="reading-ruler"
      :style="{ top: rulerY + 'px' }"
    ></div>
    </template>
  </EbookContainer>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref, reactive, provide, watch, nextTick } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useEbookStore } from '@/composables/useEbookStore'
import { useLazySections } from '@/composables/useLazySections'
import { usePaginatedMode } from '@/composables/usePaginatedMode'
import { useReadingRuler } from '@/composables/useReadingRuler'
import { useBookmarks } from '@/composables/useBookmarks'
import { useReadingStats } from '@/composables/useReadingStats'
import { useTts } from '@/composables/useTts'
import { useKeyboardShortcuts } from '@/composables/useKeyboardShortcuts'
import { useScrollTracker } from '@/composables/useScrollTracker'
import { isDomFormat } from '@/composables/useContentLoader'
import { useCollectionStore, type BookMeta } from '@/stores/collectionStore'
import LibraryIndex from '@/components/library/LibraryIndex.vue'
import AppSidebar from '@/components/AppSidebar.vue'
import SearchModal from '@/components/SearchModal.vue'
import SettingsPanel from '@/components/SettingsPanel.vue'
import MirrorRenderer from '@/components/MirrorRenderer.vue'
import RefCardSwiper from '@/components/RefCardSwiper.vue'
import EbookTopBar from '@/components/EbookTopBar.vue'
import EbookContainer from '@/components/EbookContainer.vue'
import BreadcrumbBar from '@/components/BreadcrumbBar.vue'
import ImageLightbox from '@/components/ImageLightbox.vue'
import ListOfSection from '@/components/ListOfSection.vue'
import ReadingProgressBar from '@/components/ReadingProgressBar.vue'
import KeyboardHelp from '@/components/KeyboardHelp.vue'
import SectionNav from '@/components/SectionNav.vue'
import TitlePage from '@/components/TitlePage.vue'
import { findAncestorChain } from '@/utils/breadcrumb'

const documentStore = useDocumentStore()
const uiStore = useUiStore()
const ebookStore = useEbookStore()
const mainContent = ref<HTMLElement | null>(null)

// DOM format: content is pre-rendered in #docbook-content, skip MirrorRenderer
const useDomContent = isDomFormat()

// Library mode (collection)
const collectionStore = useCollectionStore()
const isLibraryMode = ref(false)
const showLibraryIndex = computed(() => isLibraryMode.value && !collectionStore.isReading)
const isLibraryDark = computed(() => ebookStore.theme.value === 'night' || ebookStore.theme.value === 'oled')

// Lazy section rendering
const { isVisible, observeSection, markVisible, initialized: lazyInitialized, reset: resetLazySections, createObserver: createLazyObserver } = useLazySections(mainContent)
provide('lazySectionVisible', isVisible)
provide('lazyObserveSection', observeSection)
provide('lazyInitialized', lazyInitialized)

// Paginated reading mode
const {
  currentPage, totalPages, progress: pageProgress,
  calculatePages, nextPage, prevPage, handleScroll: handlePagedScroll,
} = usePaginatedMode(mainContent)

// Recalculate pages when reading mode or document changes
watch(() => [ebookStore.readingMode.value, documentStore.mirrorDocument], () => {
  nextTick(() => calculatePages())
}, { immediate: false })

// Reading ruler
const { enabled: rulerEnabled, rulerY, toggle: toggleRuler } = useReadingRuler()

// Bookmarks
const bookmarks = useBookmarks(documentStore.title)
provide('bookmarks', bookmarks)

// Compute content style directly from store state
const contentStyle = computed(() => {
  const vars = ebookStore.getCssVariables()
  return { maxWidth: vars['--ebook-max-width'], margin: '0 auto' }
})

// Keyboard help overlay
const showKeyboardHelp = ref(false)

// Focus mode: reveal topbar on mouse proximity to top
const focusRevealTopbar = ref(false)

// Image lightbox state
const lightbox = reactive({ visible: false, src: '', alt: '', title: '' })

provide('lightbox', {
  open(src: string, alt?: string, title?: string) {
    lightbox.visible = true
    lightbox.src = src
    lightbox.alt = alt || ''
    lightbox.title = title || ''
  }
})

provide('navigateToId', navigateToId)

function toggleToc() { uiStore.toggleSidebar() }
function exitFocusMode() { ebookStore.setFocusMode(false) }
function handleOverlayClick() { uiStore.closeSidebar() }

// Lists of figures/tables/examples
const hasLists = computed(() => {
  const lo = documentStore.listOf
  return (lo.figures?.length ?? 0) + (lo.tables?.length ?? 0) + (lo.examples?.length ?? 0) > 0
})

// Build ancestor chain for breadcrumb
const ancestorChain = computed(() => {
  if (!uiStore.activeSectionId) return []
  const chain = findAncestorChain(documentStore.sections, uiStore.activeSectionId)
  return chain.map((item, i) => ({
    id: item.id, title: item.title, type: item.type,
    number: documentStore.getNumbering(item.id),
    isRoot: i === 0, isLeaf: i === chain.length - 1
  }))
})

function findSectionById(sections: TocItem[], id: string): TocItem | null {
  for (const section of sections) {
    if (section.id === id) return section
    if (section.children) {
      const found = findSectionById(section.children, id)
      if (found) return found
    }
  }
  return null
}

// Flatten section IDs in document order for keyboard navigation
const sectionIds = computed(() => {
  const ids: string[] = []
  function walk(items: TocItem[]) {
    for (const item of items) {
      ids.push(item.id)
      if (item.children) walk(item.children)
    }
  }
  walk(documentStore.sections)
  return ids
})

// Active section index for SectionNav
const activeSectionIndex = computed(() =>
  sectionIds.value.indexOf(uiStore.activeSectionId || '')
)

// Reading statistics
const readingStats = useReadingStats(documentStore.title, sectionIds.value.length, sectionIds.value)
provide('readingStats', readingStats)

// Text-to-speech
const tts = useTts()

// Scroll tracking (reading progress, back-to-top, active section)
const { readingProgress, showBackToTop, handleScroll, updateActiveSection } = useScrollTracker({
  mainContent, documentStore, uiStore, readingStats,
})

// Keyboard shortcuts
const { handleGlobalKeydown } = useKeyboardShortcuts({
  showKeyboardHelp, ebookStore, uiStore, documentStore,
  sectionIds, navigateToId, toggleRuler,
  toggleBookmark: () => {
    const activeId = uiStore.activeSectionId
    if (activeId) {
      const section = findSectionById(documentStore.sections, activeId)
      if (section) bookmarks.toggle(activeId, section.title)
    }
  },
  ttsPlay: () => tts.speak(),
  ttsStop: () => { if (tts.speaking.value) tts.stop() },
  nextPage, prevPage,
})

// Refentry card swiper
const refEntries = computed(() => {
  const doc = documentStore.mirrorDocument
  if (!doc?.content) return []
  const entries: any[] = []
  function collect(nodes: any[]) {
    for (const node of nodes) {
      if (node.type === 'refentry') entries.push(node)
      if (node.content) collect(node.content)
    }
  }
  collect(doc.content)
  return entries
})

const showSectionNav = computed(() =>
  !ebookStore.focusMode.value && activeSectionIndex.value >= 0
)

const sectionAnnouncement = computed(() => {
  const id = uiStore.activeSectionId
  if (!id) return ''
  const section = findSectionById(documentStore.sections, id)
  return section ? section.title : ''
})

// Navigate to an element by ID, scrolling within the main container
function navigateToId(id: string) {
  if (!mainContent.value) return
  markVisible(id)
  const chain = findAncestorChain(documentStore.sections, id)
  for (const ancestor of chain) markVisible(ancestor.id)

  nextTick(() => {
    const element = document.getElementById(id)
    if (!element) return
    const container = mainContent.value!
    const containerRect = container.getBoundingClientRect()
    const elementRect = element.getBoundingClientRect()
    const scrollTarget = elementRect.top - containerRect.top + container.scrollTop - 70
    container.scrollTo({ top: scrollTarget, behavior: 'smooth' })
    history.replaceState(null, '', `#${id}`)
  })
}

// Intercept all clicks on hash links
function handleDocumentClick(e: MouseEvent) {
  const target = e.target as HTMLElement
  const link = target.closest('a[href^="#"]') as HTMLAnchorElement | null
  if (!link) return
  e.preventDefault()
  const id = link.getAttribute('href')!.slice(1)
  if (id) navigateToId(id)
}

function handleHashChange() {
  const hash = window.location.hash
  if (!hash) return
  const id = hash.slice(1)
  if (id) setTimeout(() => navigateToId(id), 100)
}

function handleMouseMove(e: MouseEvent) {
  focusRevealTopbar.value = ebookStore.focusMode.value && e.clientY < 48
}

function onScroll() {
  if (ebookStore.readingMode.value === 'paged') handlePagedScroll()
  handleScroll()
}

function scrollToTop() {
  mainContent.value?.scrollTo({ top: 0, behavior: 'smooth' })
}

function skipToContent() {
  mainContent.value?.focus()
  mainContent.value?.scrollTo({ top: 0 })
}

// Library mode: load book data when a book is selected
watch(() => collectionStore.currentBookId, async (bookId) => {
  if (!isLibraryMode.value || !bookId) return
  await loadLibraryBook()
})

async function loadLibraryBook() {
  const book = collectionStore.currentBook as (BookMeta & { data?: any }) | null
  if (!book) return

  // Reset lazy sections for the new book
  resetLazySections()

  if (book.data) {
    ;(window as any).DOCBOOK_DATA = book.data
    documentStore.loadFromWindow()
  } else if (book.source) {
    try {
      const res = await fetch(book.source)
      if (res.ok) {
        const data = await res.json()
        ;(window as any).DOCBOOK_DATA = data
        documentStore.loadFromWindow()
      }
    } catch (e) {
      console.error('Failed to load book:', e)
    }
  }

  await nextTick()
  // Recreate the lazy observer now that mainContent is in the DOM
  createLazyObserver()
  setTimeout(() => {
    updateActiveSection()
    handleHashChange()
    calculatePages()
    if (window.innerWidth >= 1024) uiStore.openSidebar()
  }, 200)

  history.pushState({ mode: 'book', bookId: book.id }, '', `#book-${book.id}`)
}

function backToLibrary() {
  collectionStore.closeBook()
  history.pushState({ mode: 'library' }, '', '#')
}

function handlePopState(e: PopStateEvent) {
  if (!isLibraryMode.value) return
  if (e.state?.mode === 'book' && e.state.bookId) {
    collectionStore.selectBook(e.state.bookId)
  } else {
    collectionStore.closeBook()
  }
}

function onLibraryBookOpened(_book: BookMeta) {
  // Book selection is handled by the currentBookId watcher
}

// Wrap keyboard handler to skip when showing library index
function onGlobalKeydown(e: KeyboardEvent) {
  if (showLibraryIndex.value) return
  handleGlobalKeydown(e)
}

onMounted(() => {
  if ((window as any).DOCBOOK_COLLECTION) {
    isLibraryMode.value = true
    collectionStore.loadFromWindow()
    history.replaceState({ mode: 'library' }, '', '')
  } else {
    documentStore.loadFromWindow()
    delete (window as any).DOCBOOK_DATA
  }
  ebookStore.applyTheme()
  if (ebookStore.settingsOpen.value) ebookStore.toggleSettings()
  if (window.innerWidth >= 1024 && !isLibraryMode.value) uiStore.openSidebar()

  document.addEventListener('click', handleDocumentClick)
  window.addEventListener('hashchange', handleHashChange)
  document.addEventListener('keydown', onGlobalKeydown)
  document.addEventListener('mousemove', handleMouseMove)
  window.addEventListener('popstate', handlePopState)

  if (!isLibraryMode.value) {
    setTimeout(() => {
      updateActiveSection()
      handleHashChange()
      calculatePages()
      if (!window.location.hash) {
        try {
          const saved = localStorage.getItem('docbook-position-' + documentStore.title)
          if (saved && document.getElementById(saved)) navigateToId(saved)
        } catch {}
      }
    }, 200)
  }
})

onUnmounted(() => {
  document.removeEventListener('click', handleDocumentClick)
  window.removeEventListener('hashchange', handleHashChange)
  document.removeEventListener('keydown', onGlobalKeydown)
  document.removeEventListener('mousemove', handleMouseMove)
  window.removeEventListener('popstate', handlePopState)
})
</script>

<style scoped>
.skip-link {
  position: absolute;
  top: -100px;
  left: 0;
  background: var(--chrome-accent);
  color: #fff;
  padding: 8px 16px;
  z-index: 100;
  font-size: 0.85rem;
  font-weight: 600;
  border-radius: 0 0 8px 0;
  text-decoration: none;
  transition: top 0.1s;
}

.skip-link:focus {
  top: 0;
}

.app-footer {
  border-color: var(--ebook-border);
  color: var(--ebook-text-muted);
}

.app-footer-link {
  color: var(--ebook-link-color);
}

.focus-mode-topbar {
  transition: opacity 0.2s ease;
}

.focus-mode-topbar--hidden {
  opacity: 0;
  pointer-events: none;
}

.focus-mode-topbar--reveal {
  opacity: 1;
  pointer-events: auto;
}

.focus-mode-indicator {
  position: fixed;
  bottom: 24px;
  right: 24px;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 999px;
  background: var(--chrome-accent);
  color: #fff;
  border: none;
  cursor: pointer;
  box-shadow: 0 2px 12px rgba(0,0,0,0.2);
  transition: opacity 0.2s ease, transform 0.2s ease;
  z-index: 30;
}
.focus-mode-indicator:hover {
  opacity: 0.9;
  transform: scale(1.05);
}

.back-to-top {
  position: fixed;
  bottom: 24px;
  right: 24px;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--chrome-bg-glass);
  color: var(--chrome-text);
  border: 1px solid var(--chrome-border);
  backdrop-filter: blur(8px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
  cursor: pointer;
  z-index: 35;
  transition: background 0.15s ease, transform 0.15s ease;
}

.back-to-top:hover {
  background: var(--chrome-bg-hover);
  transform: translateY(-2px);
}

.back-to-top-fade-enter-active,
.back-to-top-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.back-to-top-fade-enter-from,
.back-to-top-fade-leave-to {
  opacity: 0;
  transform: translateY(16px);
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* Paged reading mode */
.paged-mode {
  scroll-snap-type: y mandatory;
  scroll-behavior: smooth;
}

/* Page navigation */
.page-nav {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: var(--chrome-bg-glass);
  border: 1px solid var(--chrome-border);
  border-radius: 999px;
  backdrop-filter: blur(8px);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.12);
  z-index: 40;
}

.page-nav-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  color: var(--chrome-text);
  transition: background 0.15s ease;
}

.page-nav-btn:hover:not(:disabled) {
  background: var(--chrome-bg-hover);
}

.page-nav-btn:disabled {
  opacity: 0.3;
  cursor: default;
}

.page-nav-info {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--chrome-text-dim);
  min-width: 60px;
  text-align: center;
  font-variant-numeric: tabular-nums;
}

/* Reading ruler */
.reading-ruler {
  position: fixed;
  left: 0;
  right: 0;
  height: 2em;
  pointer-events: none;
  z-index: 25;
  background: color-mix(in srgb, var(--ebook-accent) 12%, transparent);
  border-top: 1px solid color-mix(in srgb, var(--ebook-accent) 30%, transparent);
  border-bottom: 1px solid color-mix(in srgb, var(--ebook-accent) 30%, transparent);
  transform: translateY(-1em);
  transition: top 0.05s ease-out;
}

/* TTS indicator */
.tts-indicator {
  position: fixed;
  bottom: 24px;
  left: 24px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 999px;
  background: var(--chrome-accent);
  color: #fff;
  border: none;
  box-shadow: 0 2px 12px rgba(0,0,0,0.2);
  z-index: 30;
}

.tts-btn {
  display: flex;
  align-items: center;
  color: #fff;
  opacity: 0.8;
  transition: opacity 0.15s ease;
}

.tts-btn:hover {
  opacity: 1;
}

.tts-label {
  font-size: 0.75rem;
}
</style>

<style>
/* Library Index CSS Variables */
.library-index-wrapper {
  --color-bg: #faf8f5;
  --color-surface: #ffffff;
  --color-surface-elevated: #f5f3f0;
  --color-text: #2d2d2d;
  --color-text-secondary: #5c5c5c;
  --color-text-muted: #8a8a8a;
  --color-border: #e8e4df;
  --color-accent: #b8860b;
  --color-accent-hover: #9a7209;
  --font-display: 'Cormorant Garamond', Georgia, serif;
  --font-body: 'Source Serif Pro', Georgia, serif;
  --font-ui: 'Source Sans 3', system-ui, sans-serif;
  height: 100vh;
  overflow-y: auto;
  background: var(--color-bg);
  color: var(--color-text);
  transition: background 0.3s ease, color 0.3s ease;
}

.library-index-wrapper.dark {
  --color-bg: #1a1a1a;
  --color-surface: #242424;
  --color-surface-elevated: #2d2d2d;
  --color-text: #f0f0f0;
  --color-text-secondary: #b0b0b0;
  --color-text-muted: #707070;
  --color-border: #3d3d3d;
  --color-accent: #d4a84b;
  --color-accent-hover: #e5b94d;
}
</style>
