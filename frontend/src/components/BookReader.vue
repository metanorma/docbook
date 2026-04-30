<template>
  <a href="#main-content" class="skip-link" @click.prevent="skipToContent">Skip to content</a>

  <!-- Reading progress bar -->
  <ReadingProgressBar :progress="readingProgress" :visible="ebookStore.showProgress" />

  <!-- Mobile overlay -->
  <div
    v-if="uiStore.sidebarOpen"
    @click="handleOverlayClick"
    class="fixed inset-0 bg-black/50 z-40"
    :class="{ 'lg:hidden': !ebookStore.focusMode }"
  ></div>

  <AppSidebar v-show="!ebookStore.focusMode || uiStore.sidebarOpen" />

  <!-- Ebook Top Bar -->
  <div :class="['focus-mode-topbar', { 'focus-mode-topbar--hidden': ebookStore.focusMode && !uiStore.sidebarOpen && !focusRevealTopbar, 'focus-mode-topbar--reveal': (ebookStore.focusMode && focusRevealTopbar) || (ebookStore.focusMode && uiStore.sidebarOpen) }]">
    <EbookTopBar
      :title="documentStore.title"
      :current-chapter="currentChapter"
      :sidebar-open="uiStore.sidebarOpen"
      :show-back-to-library="showBackToLibrary"
      :read-pct="readingStats.readPercentage.value"
      @toggle-toc="toggleToc"
      @toggle-settings="ebookStore.toggleSettings"
      @back-to-library="$emit('backToLibrary')"
    />
  </div>

  <!-- Focus mode indicator -->
  <button
    v-if="ebookStore.focusMode && !uiStore.sidebarOpen"
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
    !ebookStore.focusMode ? 'pt-14' : 'pt-0',
    uiStore.sidebarOpen ? 'lg:pl-[280px]' : '',
    ebookStore.readingMode === 'paged' ? 'paged-mode' : ''
  ]" @scroll="onScroll">
    <!-- Active section breadcrumb -->
    <BreadcrumbBar v-if="ancestorChain.length > 0 && !ebookStore.focusMode" :ancestor-chain="ancestorChain" />

    <div class="px-6 py-10 lg:px-8 lg:py-12 mx-auto transition-[max-width] duration-300 ease-out" :style="contentStyle">
      <!-- Error state -->
      <div v-if="documentStore.loadError" class="error-state">
        <svg class="error-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        <h2>Failed to load document</h2>
        <p class="error-detail">{{ documentStore.loadError }}</p>
        <button @click="retryLoad" class="error-retry">Retry</button>
      </div>

      <!-- Loading state -->
      <div v-else-if="!documentStore.mirrorDocument && !useDomContent" class="loading-state">
        <div class="loading-skeleton">
          <div class="skeleton-title"></div>
          <div class="skeleton-line w-3/4"></div>
          <div class="skeleton-line w-full"></div>
          <div class="skeleton-line w-5/6"></div>
          <div class="skeleton-line w-2/3"></div>
          <div class="skeleton-spacer"></div>
          <div class="skeleton-heading"></div>
          <div class="skeleton-line w-full"></div>
          <div class="skeleton-line w-4/5"></div>
          <div class="skeleton-line w-full"></div>
          <div class="skeleton-line w-3/4"></div>
        </div>
      </div>

      <!-- Content (shown after load) -->
      <template v-else>
      <!-- Title page -->
      <TitlePage
        v-if="documentStore.title && documentStore.title !== 'DocBook Document'"
        :title="documentStore.title"
        :subtitle="documentStore.subtitle"
        :author="documentStore.author"
        :pubdate="documentStore.pubdate"
        :copyright="documentStore.copyright"
        :cover="documentStore.cover"
        :section-count="documentStore.sections.length"
      />

      <!-- DocbookMirror format (ProseMirror-style) -->
      <div v-if="useDomContent" id="docbook-content" class="db-content" :class="{ 'db-content--reveal': contentRevealed }">
        <!-- DOM format: content is pre-rendered by Ruby HtmlRenderer, already in #docbook-content -->
      </div>
      <div v-else-if="documentStore.mirrorDocument" class="db-content" :class="{ 'db-content--reveal': contentRevealed }">
        <!-- Reference card swiper mode -->
        <RefCardSwiper
          v-if="ebookStore.refCardMode && refEntries.length > 0"
          :entries="refEntries"
        />
        <!-- Default mirror renderer -->
        <MirrorRenderer v-else :blocks="documentStore.mirrorDocument.content || []" :top="true" />

        <!-- Lists of figures/tables/examples -->
        <ListOfSection
          v-if="hasLists"
          :list-of="documentStore.listOf"
        />
      </div>

      <!-- Chunked format: sentinel triggers loading next section -->
      <div v-if="isChunked && !chunkedLoader.allContentLoaded.value" ref="sentinelEl" class="chunked-sentinel">
        <div class="loading-spinner"></div>
      </div>

      <!-- End-of-document card -->
      <footer class="doc-fin">
        <div class="doc-fin-rule"></div>
        <div class="doc-fin-check">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 class="doc-fin-title">End of document</h3>
        <div v-if="readingStats && readingStats.totalSections > 0" class="doc-fin-stats">
          <div class="doc-fin-stat">
            <span class="doc-fin-stat-value">{{ readingStats.sectionsReadCount.value }}<span class="doc-fin-stat-total">/{{ readingStats.totalSections }}</span></span>
            <span class="doc-fin-stat-label">Sections read</span>
          </div>
          <div class="doc-fin-stat-divider"></div>
          <div class="doc-fin-stat">
            <span class="doc-fin-stat-value">{{ readingStats.readPercentage.value }}%</span>
            <span class="doc-fin-stat-label">Complete</span>
          </div>
          <template v-if="readingStats.activeReadingMinutes.value > 0">
            <div class="doc-fin-stat-divider"></div>
            <div class="doc-fin-stat">
              <span class="doc-fin-stat-value">{{ readingStats.activeReadingMinutes.value }}<span class="doc-fin-stat-total">m</span></span>
              <span class="doc-fin-stat-label">Active reading</span>
            </div>
          </template>
        </div>
        <div class="doc-fin-actions">
          <button @click="scrollToTop" class="doc-fin-btn">Back to top</button>
          <button v-if="showBackToLibrary" @click="$emit('backToLibrary')" class="doc-fin-btn doc-fin-btn--accent">Return to library</button>
        </div>
        <p class="doc-fin-credit">Generated by <a href="https://github.com/metanorma/metanorma-docbook" class="doc-fin-credit-link">Metanorma Docbook</a></p>
      </footer>
      </template>
    </div>
  </main>

  <SearchModal />
  <SettingsPanel />
  <ToastContainer />
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

  <!-- Back to top (hidden in paged mode — page nav provides navigation) -->
  <Transition name="back-to-top-fade">
    <button v-if="showBackToTop && ebookStore.readingMode !== 'paged'" class="back-to-top" @click="scrollToTop" title="Back to top">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/>
      </svg>
    </button>
  </Transition>

  <!-- Screen reader announcements -->
  <div role="status" aria-live="polite" aria-atomic="true" class="sr-only">{{ sectionAnnouncement }}</div>

  <!-- Page navigation for paged mode -->
  <div v-if="ebookStore.readingMode === 'paged'" class="page-nav">
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

<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref, reactive, provide, watch, nextTick } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useEbookStore } from '@/stores/ebookStore'
import { useLazySections } from '@/composables/useLazySections'
import { usePaginatedMode } from '@/composables/usePaginatedMode'
import { useReadingRuler } from '@/composables/useReadingRuler'
import { useBookmarks } from '@/composables/useBookmarks'
import { useReadingStats } from '@/composables/useReadingStats'
import { useTts } from '@/composables/useTts'
import { useKeyboardShortcuts } from '@/composables/useKeyboardShortcuts'
import { useScrollTracker } from '@/composables/useScrollTracker'
import { isDomFormat, isChunkedFormat } from '@/composables/useContentLoader'
import { useChunkedLoader } from '@/composables/useChunkedLoader'
import { useSwipeGesture } from '@/composables/useSwipeGesture'
import AppSidebar from '@/components/AppSidebar.vue'
import SearchModal from '@/components/SearchModal.vue'
import SettingsPanel from '@/components/SettingsPanel.vue'
import MirrorRenderer from '@/components/MirrorRenderer.vue'
import RefCardSwiper from '@/components/RefCardSwiper.vue'
import EbookTopBar from '@/components/EbookTopBar.vue'
import BreadcrumbBar from '@/components/BreadcrumbBar.vue'
import ImageLightbox from '@/components/ImageLightbox.vue'
import ListOfSection from '@/components/ListOfSection.vue'
import ReadingProgressBar from '@/components/ReadingProgressBar.vue'
import KeyboardHelp from '@/components/KeyboardHelp.vue'
import SectionNav from '@/components/SectionNav.vue'
import TitlePage from '@/components/TitlePage.vue'
import ToastContainer from '@/components/ToastContainer.vue'
import { findAncestorChain } from '@/utils/breadcrumb'
import { useToast } from '@/composables/useToast'

defineProps<{
  showBackToLibrary?: boolean
}>()

defineEmits<{
  backToLibrary: []
}>()

const documentStore = useDocumentStore()
const uiStore = useUiStore()
const ebookStore = useEbookStore()
const mainContent = ref<HTMLElement | null>(null)
const { addToast } = useToast()

// DOM format: content is pre-rendered in #docbook-content, skip MirrorRenderer
const useDomContent = isDomFormat()
const isChunked = isChunkedFormat()

// Content reveal animation
const contentRevealed = ref(false)

// Mobile swipe gestures: swipe from left edge opens sidebar
useSwipeGesture({
  onSwipeRight: () => { if (window.innerWidth < 1024 && !uiStore.sidebarOpen) uiStore.openSidebar() },
  onSwipeLeft: () => { if (window.innerWidth < 1024 && uiStore.sidebarOpen) uiStore.closeSidebar() },
})

// Chunked format: lazy section loading with IndexedDB cache
const chunkedLoader = useChunkedLoader(mainContent)
const sentinelEl = ref<HTMLElement | null>(null)

// When new sections load, update the document store
watch(() => chunkedLoader.loadedSections.value.size, () => {
  if (!isChunked) return
  const content = chunkedLoader.getAssembledContent()
  documentStore.mirrorDocument = { type: 'doc', content } as any
})

// Lazy section rendering
const { isVisible, observeSection, markVisible, initialized: lazyInitialized, reset: resetLazySections, createObserver: createLazyObserver, setTotalBlocks, revealedCount } = useLazySections(mainContent)
provide('lazySectionVisible', isVisible)
provide('lazyObserveSection', observeSection)
provide('lazyInitialized', lazyInitialized)
provide('progressiveRevealedCount', revealedCount)

// Paginated reading mode
const {
  currentPage, totalPages, progress: pageProgress,
  calculatePages, nextPage, prevPage, handleScroll: handlePagedScroll,
} = usePaginatedMode(mainContent)

watch(() => [ebookStore.readingMode, documentStore.mirrorDocument], () => {
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

// Progressive rendering: set total block count when document loads
watch(() => documentStore.mirrorDocument?.content?.length, (len) => {
  if (len) setTotalBlocks(len)
}, { immediate: true })

// Content reveal: trigger first-appear animation when document loads
watch(() => documentStore.mirrorDocument, (doc) => {
  if (doc) {
    nextTick(() => { contentRevealed.value = true })
  }
}, { immediate: true })

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

// Current chapter for topbar display
const currentChapter = computed(() => {
  if (!uiStore.activeSectionId) return ''
  const section = findSectionById(documentStore.sections, uiStore.activeSectionId)
  return section?.title || ''
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
const { readingProgress, showBackToTop, handleScroll, updateActiveSection, restoreScrollPosition } = useScrollTracker({
  mainContent, documentStore, uiStore, readingStats,
})

// Reading milestone toasts at 25%, 50%, 75%
const shownMilestones = new Set<number>()
watch(readingProgress, (pct) => {
  const milestones = [25, 50, 75]
  for (const m of milestones) {
    if (pct >= m && !shownMilestones.has(m)) {
      shownMilestones.add(m)
      addToast(`${m}% read — ${readingStats.sectionsReadCount.value} of ${readingStats.totalSections} sections`, 'info')
    }
  }
})

// Keyboard shortcuts
const { handleGlobalKeydown } = useKeyboardShortcuts({
  showKeyboardHelp, ebookStore, uiStore, documentStore,
  sectionIds, navigateToId, toggleRuler,
  toggleBookmark: () => {
    const activeId = uiStore.activeSectionId
    if (activeId) {
      const section = findSectionById(documentStore.sections, activeId)
      if (section) {
        const wasBookmarked = bookmarks.isBookmarked(activeId)
        bookmarks.toggle(activeId, section.title)
        addToast(
          wasBookmarked ? `Bookmark removed` : `Bookmarked: ${section.title}`,
          wasBookmarked ? 'info' : 'success'
        )
      }
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
  !ebookStore.focusMode && activeSectionIndex.value >= 0
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

    // Highlight the heading to confirm arrival
    const heading = element.querySelector('.heading-with-anchor') || element.querySelector('h1, h2, h3, h4')
    if (heading) {
      heading.classList.add('section-arrival-highlight')
      setTimeout(() => heading.classList.remove('section-arrival-highlight'), 1500)
    }
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
  focusRevealTopbar.value = ebookStore.focusMode && e.clientY < 48
}

function onScroll() {
  if (ebookStore.readingMode === 'paged') handlePagedScroll()
  handleScroll()
}

function scrollToTop() {
  mainContent.value?.scrollTo({ top: 0, behavior: 'smooth' })
}

function skipToContent() {
  mainContent.value?.focus()
  mainContent.value?.scrollTo({ top: 0 })
}

function retryLoad() {
  documentStore.loadFromWindow()
}

onMounted(() => {
  document.addEventListener('click', handleDocumentClick)
  window.addEventListener('hashchange', handleHashChange)
  document.addEventListener('keydown', handleGlobalKeydown)
  document.addEventListener('mousemove', handleMouseMove)

  if (window.innerWidth >= 1024) uiStore.openSidebar()

  // Set up sentinel observer for chunked format
  if (isChunked) {
    chunkedLoader.setupSentinelObserver()
    nextTick(() => {
      if (sentinelEl.value) {
        chunkedLoader.observeSentinel(sentinelEl.value)
      }
    })
  }

  setTimeout(() => {
    updateActiveSection()
    handleHashChange()
    calculatePages()
    if (!window.location.hash) {
      restoreScrollPosition()
    }
  }, 200)
})

onUnmounted(() => {
  document.removeEventListener('click', handleDocumentClick)
  window.removeEventListener('hashchange', handleHashChange)
  document.removeEventListener('keydown', handleGlobalKeydown)
  document.removeEventListener('mousemove', handleMouseMove)
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

/* Content first-appear animation */
:deep(.db-content--reveal) {
  animation: content-reveal 0.5s cubic-bezier(0.16, 1, 0.3, 1) both;
}

@keyframes content-reveal {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* End-of-document card */
.doc-fin {
  margin-top: 6rem;
  padding: 3rem 1rem 2rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.doc-fin-rule {
  width: 100px;
  height: 1px;
  background: linear-gradient(to right, transparent, color-mix(in srgb, var(--ebook-accent) 40%, var(--ebook-border)), transparent);
  margin-bottom: 2rem;
}

.doc-fin-check {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: color-mix(in srgb, var(--ebook-accent) 10%, transparent);
  border: 1.5px solid color-mix(in srgb, var(--ebook-accent) 25%, transparent);
  color: var(--ebook-accent);
  margin-bottom: 1rem;
  animation: doc-fin-pop 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
}

@keyframes doc-fin-pop {
  from { transform: scale(0.6); opacity: 0; }
  60% { transform: scale(1.05); }
  to { transform: scale(1); opacity: 1; }
}

.doc-fin-check svg {
  width: 24px;
  height: 24px;
}

.doc-fin-title {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: var(--ebook-text-muted);
  margin: 0 0 1.5rem;
}

.doc-fin-stats {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 24px;
  background: color-mix(in srgb, var(--ebook-bg-secondary) 60%, transparent);
  border: 1px solid var(--ebook-border);
  border-radius: 12px;
  margin-bottom: 1.5rem;
}

.doc-fin-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.doc-fin-stat-value {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--ebook-text-heading);
  font-variant-numeric: tabular-nums;
}

.doc-fin-stat-total {
  font-size: 0.75em;
  font-weight: 500;
  color: var(--ebook-text-muted);
}

.doc-fin-stat-label {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.62rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--ebook-text-muted);
}

.doc-fin-stat-divider {
  width: 1px;
  height: 28px;
  background: var(--ebook-border);
}

.doc-fin-actions {
  display: flex;
  gap: 8px;
  margin-bottom: 2rem;
}

.doc-fin-btn {
  padding: 9px 20px;
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.78rem;
  font-weight: 500;
  border-radius: 8px;
  border: 1px solid var(--ebook-border);
  color: var(--ebook-text);
  background: transparent;
  cursor: pointer;
  transition: background 0.15s ease, border-color 0.15s ease;
}

.doc-fin-btn:hover {
  background: var(--ebook-bg-secondary);
  border-color: var(--ebook-text-muted);
}

.doc-fin-btn--accent {
  background: var(--chrome-accent);
  color: #fff;
  border-color: transparent;
}

.doc-fin-btn--accent:hover {
  opacity: 0.9;
  background: var(--chrome-accent);
}

.doc-fin-credit {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.6rem;
  color: var(--ebook-text-muted);
  opacity: 0.4;
  margin: 0;
  letter-spacing: 0.02em;
}

.doc-fin-credit-link {
  color: var(--ebook-text-muted);
  text-decoration: none;
}

.doc-fin-credit-link:hover {
  text-decoration: underline;
}

/* Error state */
.error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 50vh;
  gap: 0.75rem;
  text-align: center;
}
.error-icon {
  width: 40px;
  height: 40px;
  color: #f59e0b;
}
.error-state h2 {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--chrome-text);
}
.error-detail {
  font-size: 0.85rem;
  color: var(--chrome-text-dim);
  max-width: 300px;
}
.error-retry {
  margin-top: 0.5rem;
  padding: 8px 20px;
  font-size: 0.8rem;
  font-weight: 600;
  border-radius: 8px;
  background: var(--chrome-accent);
  color: #fff;
  cursor: pointer;
}
.error-retry:hover {
  opacity: 0.9;
}

/* Skeleton loading screen */
.loading-skeleton {
  max-width: 500px;
  margin: 0 auto;
  padding-top: 2rem;
}
.skeleton-title {
  height: 32px;
  width: 60%;
  border-radius: 6px;
  background: var(--chrome-bg-hover);
  margin-bottom: 1.5rem;
  animation: skeleton-pulse 1.5s ease-in-out infinite;
}
.skeleton-heading {
  height: 20px;
  width: 40%;
  border-radius: 4px;
  background: var(--chrome-bg-hover);
  margin-bottom: 1rem;
  animation: skeleton-pulse 1.5s ease-in-out infinite;
  animation-delay: 0.1s;
}
.skeleton-line {
  height: 14px;
  border-radius: 4px;
  background: var(--chrome-bg-hover);
  margin-bottom: 0.6rem;
  animation: skeleton-pulse 1.5s ease-in-out infinite;
}
.skeleton-spacer {
  height: 2rem;
}
@keyframes skeleton-pulse {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 1; }
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
  bottom: 72px;
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

.paged-mode {
  scroll-snap-type: y mandatory;
  scroll-behavior: smooth;
}

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

.chunked-sentinel {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  min-height: 60px;
}

.chunked-sentinel .loading-spinner {
  width: 24px;
  height: 24px;
  border: 2px solid var(--chrome-border);
  border-top-color: var(--chrome-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 40vh;
  gap: 1rem;
  color: var(--chrome-text-dim);
  font-size: 0.9rem;
}

.loading-state .loading-spinner {
  width: 36px;
  height: 36px;
  border: 3px solid var(--chrome-border);
  border-top-color: var(--chrome-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
</style>
