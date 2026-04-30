<template>
  <Transition name="library-fade" mode="out-in">
    <!-- Library Index -->
    <div v-if="!collectionStore.isReading" key="library" class="library-viewport">
      <LibraryIndex @open-book="onBookOpened" :dark="isLibraryDark" />
    </div>

    <!-- Loading state -->
    <div v-else-if="isLoading" key="loading" class="loading-state">
      <div class="loading-book">
        <div class="loading-book-spine"></div>
        <div class="loading-book-pages">
          <div class="loading-page"></div>
          <div class="loading-page"></div>
          <div class="loading-page"></div>
        </div>
      </div>
      <p class="loading-label">Opening {{ collectionStore.currentBook?.title }}...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="loadError" key="error" class="error-state">
      <svg class="error-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
      <h3>Failed to load book</h3>
      <p class="error-detail">{{ loadError }}</p>
      <div class="error-actions">
        <button @click="retryLoad" class="retry-btn">Retry</button>
        <button @click="backToLibrary" class="back-btn">Back to library</button>
      </div>
    </div>

    <!-- Book reader -->
    <div v-else key="reader" class="reader-viewport">
      <BookReader show-back-to-library @back-to-library="backToLibrary" />
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted, watch } from 'vue'
import { useEbookStore } from '@/stores/ebookStore'
import { useDocumentStore } from '@/stores/documentStore'
import { useCollectionStore, type BookMeta } from '@/stores/collectionStore'
import LibraryIndex from '@/components/library/LibraryIndex.vue'
import BookReader from '@/components/BookReader.vue'

const ebookStore = useEbookStore()
const documentStore = useDocumentStore()
const collectionStore = useCollectionStore()

const isLibraryDark = computed(() => ebookStore.theme === 'night' || ebookStore.theme === 'oled')

const isLoading = ref(false)
const loadError = ref<string | null>(null)

watch(() => collectionStore.currentBookId, async (bookId) => {
  if (!bookId) return
  await loadLibraryBook()
})

async function loadLibraryBook() {
  const book = collectionStore.currentBook as (BookMeta & { data?: any }) | null
  if (!book) return

  isLoading.value = true
  loadError.value = null

  try {
    const data = collectionStore.getPrefetchedData(book.id) || book.data
    if (data) {
      ;(window as any).DOCBOOK_DATA = data
      documentStore.loadFromWindow()
    } else if (book.source) {
      const res = await fetch(book.source)
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`)
      const fetchedData = await res.json()
      ;(window as any).DOCBOOK_DATA = fetchedData
      documentStore.loadFromWindow()
    }

    history.pushState({ mode: 'book', bookId: book.id }, '', `#book-${book.id}`)
  } catch (e) {
    console.error('Failed to load book:', e)
    loadError.value = e instanceof Error ? e.message : 'Unknown error'
  } finally {
    isLoading.value = false
  }
}

async function retryLoad() {
  await loadLibraryBook()
}

function backToLibrary() {
  collectionStore.closeBook()
  loadError.value = null
  history.pushState({ mode: 'library' }, '', '#')
}

function onBookOpened(_book: BookMeta) {}

function handlePopState(e: PopStateEvent) {
  if (e.state?.mode === 'book' && e.state.bookId) {
    collectionStore.selectBook(e.state.bookId)
  } else {
    collectionStore.closeBook()
  }
}

onMounted(() => {
  window.addEventListener('popstate', handlePopState)
})

onUnmounted(() => {
  window.removeEventListener('popstate', handlePopState)
})
</script>

<style scoped>
.library-viewport,
.reader-viewport {
  height: 100vh;
  overflow: hidden;
}

.reader-viewport {
  overflow: auto;
}

/* Transitions */
.library-fade-enter-active {
  transition: opacity 0.35s ease, transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.library-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.library-fade-enter-from {
  opacity: 0;
  transform: translateY(12px);
}
.library-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* Loading state */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  gap: 1.25rem;
}

.loading-book {
  position: relative;
  width: 48px;
  height: 60px;
  perspective: 200px;
}

.loading-book-spine {
  position: absolute;
  left: 0;
  top: 0;
  width: 8px;
  height: 100%;
  background: var(--chrome-accent, #8b5e3c);
  border-radius: 3px 0 0 3px;
  opacity: 0.7;
}

.loading-book-pages {
  position: absolute;
  left: 8px;
  top: 0;
  width: 40px;
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 6px 4px;
  background: var(--chrome-bg, #f6f4f0);
  border: 1px solid var(--chrome-border, #e0ddd7);
  border-radius: 0 4px 4px 0;
  animation: book-breathe 1.5s ease-in-out infinite;
}

.loading-page {
  flex: 1;
  background: var(--chrome-bg-hover, #e8e6e0);
  border-radius: 2px;
  animation: page-fill 1.5s ease-in-out infinite;
}

.loading-page:nth-child(2) { animation-delay: 0.15s; }
.loading-page:nth-child(3) { animation-delay: 0.3s; }

@keyframes book-breathe {
  0%, 100% { transform: rotateY(0deg); }
  50% { transform: rotateY(-5deg); }
}

@keyframes page-fill {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 1; }
}

.loading-label {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--chrome-text-dim, #8a8a8a);
  animation: label-pulse 2s ease-in-out infinite;
}

@keyframes label-pulse {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 1; }
}

/* Error state */
.error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  gap: 0.75rem;
  padding: 2rem;
  text-align: center;
}

.error-state .error-icon { width: 40px; height: 40px; color: #f59e0b; }
.error-state h3 { font-size: 1.1rem; font-weight: 600; color: var(--chrome-text); }
.error-detail { font-size: 0.85rem; color: var(--chrome-text-dim); max-width: 300px; }
.error-actions { display: flex; gap: 8px; margin-top: 0.5rem; }

.retry-btn {
  padding: 8px 16px;
  font-size: 0.8rem;
  font-weight: 600;
  border-radius: 8px;
  background: var(--chrome-accent);
  color: #fff;
  cursor: pointer;
}
.back-btn {
  padding: 8px 16px;
  font-size: 0.8rem;
  font-weight: 500;
  border-radius: 8px;
  border: 1px solid var(--chrome-border);
  color: var(--chrome-text-dim);
  cursor: pointer;
}
</style>
