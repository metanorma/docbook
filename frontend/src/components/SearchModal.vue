<template>
  <Teleport to="body">
    <Transition name="search-backdrop">
      <div
        v-if="uiStore.searchOpen"
        class="search-backdrop"
        @click.self="uiStore.closeSearch"
      >
        <div ref="modalEl" class="search-modal">
          <!-- Search Input -->
          <div class="search-input-row">
            <svg class="search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
            <input
              ref="inputRef"
              v-model="searchQuery"
              type="text"
              class="search-input"
              placeholder="Search headings and content..."
              @keydown="handleKeydown"
            />
            <button v-if="searchQuery" @click="searchQuery = ''" class="search-clear">
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <!-- Results -->
          <div class="search-results">
            <div v-if="isSearching" class="search-empty">
              <div class="search-loading-ring"></div>
              <span>Searching...</span>
            </div>
            <div v-else-if="searchQuery && results.length === 0" class="search-empty">
              <div class="search-empty-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
              </div>
              <p class="search-empty-title">No results</p>
              <p class="search-empty-hint">Try a different search term</p>
            </div>
            <div v-else-if="results.length > 0" class="search-results-list">
              <a
                v-for="(result, index) in results"
                :key="result.id"
                :href="'#' + result.id"
                @click="selectResult(result)"
                class="search-result"
                :class="{ 'search-result--focused': focusedIndex === index }"
                @mouseenter="focusedIndex = index"
              >
                <div class="search-result-header">
                  <span class="search-result-type">{{ result.type }}</span>
                  <span class="search-result-title" v-html="highlightMatch(result.title)"></span>
                </div>
                <p v-if="result.snippet" class="search-result-snippet" v-html="highlightMatch(result.snippet)"></p>
              </a>
            </div>
            <div v-else class="search-empty search-empty--idle">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" class="search-idle-icon">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
              </svg>
              <span>Type to search headings and content</span>
            </div>
          </div>

          <!-- Footer hints -->
          <div class="search-footer">
            <span class="search-hint"><kbd>↑</kbd><kbd>↓</kbd> Navigate</span>
            <span class="search-hint"><kbd>↵</kbd> Open</span>
            <span class="search-hint"><kbd>esc</kbd> Close</span>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick, inject } from 'vue'
import { useDocumentStore, type TocItem, type MirrorBlockNode, type MirrorTextNode } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { SECTION_TYPES } from '@/utils/typeMetadata'
import { useFocusTrap } from '@/composables/useFocusTrap'

const documentStore = useDocumentStore()
const uiStore = useUiStore()
const navigateToId = inject<(id: string) => void>('navigateToId', () => {})

interface SearchResult {
  id: string
  title: string
  type: 'chapter' | 'appendix' | 'part' | 'section' | 'glossary' | 'bibliography' | 'index' | 'reference' | 'preface'
  snippet?: string
}

const searchQuery = ref('')
const results = ref<SearchResult[]>([])
const isSearching = ref(false)
const focusedIndex = ref(0)
const inputRef = ref<HTMLInputElement | null>(null)
const modalEl = ref<HTMLElement | null>(null)

const focusTrap = useFocusTrap(modalEl, { onEscape: () => uiStore.closeSearch() })

watch(() => uiStore.searchOpen, (open) => {
  if (open) {
    nextTick(() => focusTrap.activate())
  } else {
    focusTrap.deactivate()
  }
})

// Lazy-loaded FlexSearch
let FlexSearchClass: any = null
let flexSearchLoaded = false
let index: any = null

async function loadFlexSearch() {
  if (flexSearchLoaded) return
  const mod = await import('flexsearch')
  FlexSearchClass = (mod as any).default ?? mod
  flexSearchLoaded = true
}

function createIndex(): any {
  return new FlexSearchClass.Document({
    document: {
      id: 'id',
      index: ['title', 'body'],
      store: ['id', 'title', 'type', 'body']
    },
    tokenize: 'forward',
    resolution: 9,
    minlength: 2
  })
}

const sectionTexts = new Map<string, string>()

function extractTextFromNode(node: any): string {
  if (!node) return ''
  if (node.type === 'text') return node.text || ''
  if (node.content && Array.isArray(node.content)) {
    return node.content.map((c: any) => extractTextFromNode(c)).join(' ')
  }
  return ''
}

function buildSectionIndex(nodes: any[], parentTitle: string = '', parentType: string = '') {
  if (!nodes) return
  nodes.forEach(node => {
    if (!node || !node.attrs) return

    const xmlId = node.attrs?.xml_id
    if (!xmlId) {
      if (node.content) buildSectionIndex(node.content, parentTitle, parentType)
      return
    }

    const title = node.attrs?.title || parentTitle
    const type = node.type || parentType

    const bodyText = collectBodyText(node.content)
    const fullText = bodyText.join(' ').trim()

    if (fullText.length > 0) {
      sectionTexts.set(xmlId, fullText)
      index.add({ id: xmlId, title, type, body: fullText })
    } else if (title) {
      index.add({ id: xmlId, title, type, body: '' })
    }

    if (node.content) {
      buildSectionIndex(node.content, title, type)
    }
  })
}

function collectBodyText(content: any[] | undefined): string[] {
  if (!content) return []
  const texts: string[] = []
  content.forEach(node => {
    if (!node) return
    if (SECTION_TYPES.has(node.type) && node.attrs?.xml_id) return
    const text = extractTextFromNode(node)
    if (text) texts.push(text)
  })
  return texts
}

function buildTocIndex(items: TocItem[]) {
  items.forEach(item => {
    if (!sectionTexts.has(item.id)) {
      index.add({ id: item.id, title: item.title, type: item.type, body: '' })
    }
    if (item.children && item.children.length > 0) {
      buildTocIndex(item.children)
    }
  })
}

function getSnippet(id: string, query: string): string {
  const text = sectionTexts.get(id)
  if (!text || !query) return ''
  const lower = text.toLowerCase()
  const idx = lower.indexOf(query.toLowerCase())
  if (idx === -1) return text.slice(0, 120) + (text.length > 120 ? '...' : '')
  const start = Math.max(0, idx - 50)
  const end = Math.min(text.length, idx + query.length + 70)
  return (start > 0 ? '...' : '') + text.slice(start, end) + (end < text.length ? '...' : '')
}

function search() {
  if (!searchQuery.value.trim()) {
    results.value = []
    return
  }

  if (!index) {
    isSearching.value = true
    ensureIndex().then(() => {
      performSearch()
      isSearching.value = false
    })
    return
  }

  performSearch()
}

function performSearch() {
  isSearching.value = true

  const searchResults = index.search(searchQuery.value, { limit: 30, enrich: true })

  const combined: SearchResult[] = []
  const seen = new Set<string>()

  if (Array.isArray(searchResults)) {
    searchResults.forEach((field: { result: Array<{ id: string; doc?: any }> }) => {
      if (field.result && Array.isArray(field.result)) {
        field.result.forEach((r: { id: string; doc?: any }) => {
          if (r.doc && !seen.has(r.id)) {
            seen.add(r.id)
            combined.push({
              id: r.doc.id,
              title: r.doc.title,
              type: r.doc.type,
              snippet: getSnippet(r.doc.id, searchQuery.value)
            })
          }
        })
      }
    })
  }

  results.value = combined.slice(0, 50)
  isSearching.value = false
}

let debounceTimer: ReturnType<typeof setTimeout> | null = null
watch(searchQuery, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(search, 150)
})

let bodyIndexBuilt = false
let indexReady = false
let lastIndexedContentLength = 0

watch(() => documentStore.mirrorDocument?.content?.length, (newLen) => {
  if (!indexReady || !documentStore.isChunkedMode) return
  if (newLen && newLen > lastIndexedContentLength) {
    bodyIndexBuilt = false
    rebuildIndexes()
  }
})

async function ensureIndex() {
  if (indexReady) return
  await loadFlexSearch()
  index = createIndex()
  indexReady = true
  rebuildIndexes()
}

function rebuildIndexes() {
  if (!index) return
  buildHeadingIndex()
  if (!bodyIndexBuilt) {
    buildBodyIndex()
  }
}

function buildHeadingIndex() {
  sectionTexts.clear()
  buildTocIndex(documentStore.sections)
}

function buildBodyIndex() {
  const doc = documentStore.mirrorDocument
  if (!doc?.content) return

  try {
    if (bodyIndexBuilt) {
      sectionTexts.clear()
    }
    buildSectionIndex(doc.content)
    buildTocIndex(documentStore.sections)
  } catch (e) {
    console.error('Search index build failed:', e)
  }
  bodyIndexBuilt = true
  lastIndexedContentLength = doc.content.length
  document.body.dataset.searchIndexReady = 'true'
}

onMounted(() => {
  nextTick(() => inputRef.value?.focus())
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => ensureIndex(), { timeout: 2000 })
  } else {
    setTimeout(() => ensureIndex(), 100)
  }
})

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    focusedIndex.value = Math.min(focusedIndex.value + 1, results.value.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    focusedIndex.value = Math.max(focusedIndex.value - 1, 0)
  } else if (e.key === 'Enter' && results.value[focusedIndex.value]) {
    e.preventDefault()
    selectResult(results.value[focusedIndex.value])
  } else if (e.key === 'Escape') {
    uiStore.closeSearch()
  }
}

function selectResult(result: SearchResult) {
  navigateToId(result.id)
  const el = document.getElementById(result.id)
  if (el) {
    el.classList.add('search-highlight-flash')
    setTimeout(() => el.classList.remove('search-highlight-flash'), 2000)
  }
  uiStore.closeSearch()
  searchQuery.value = ''
  results.value = []
}

function highlightMatch(text: string): string {
  if (!searchQuery.value) return text
  const regex = new RegExp(`(${searchQuery.value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi')
  return text.replace(regex, '<mark class="search-hl">$1</mark>')
}
</script>

<style scoped>
/* Backdrop */
.search-backdrop {
  position: fixed;
  inset: 0;
  z-index: 50;
  background: rgba(0, 0, 0, 0.45);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 12vh;
}

.search-backdrop-enter-active { transition: opacity 0.2s ease; }
.search-backdrop-leave-active { transition: opacity 0.15s ease; }
.search-backdrop-enter-from,
.search-backdrop-leave-to { opacity: 0; }

/* Modal */
.search-modal {
  width: 100%;
  max-width: 560px;
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 14px;
  box-shadow:
    0 4px 12px rgba(0, 0, 0, 0.08),
    0 24px 64px rgba(0, 0, 0, 0.15);
  overflow: hidden;
  animation: modal-enter 0.25s cubic-bezier(0.16, 1, 0.3, 1) both;
}

@keyframes modal-enter {
  from { opacity: 0; transform: translateY(-12px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

/* Input row */
.search-input-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  border-bottom: 1px solid var(--chrome-border);
}

.search-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
  color: var(--chrome-text-dim);
}

.search-input {
  flex: 1;
  background: none;
  border: none;
  outline: none;
  font-size: 0.95rem;
  font-family: 'DM Sans', system-ui, sans-serif;
  color: var(--chrome-text);
}

.search-input::placeholder {
  color: var(--chrome-text-dim);
}

.search-clear {
  display: flex;
  align-items: center;
  padding: 4px;
  border-radius: 4px;
  color: var(--chrome-text-dim);
  transition: color 0.15s ease;
}

.search-clear:hover { color: var(--chrome-text); }

/* Results area */
.search-results {
  max-height: 360px;
  overflow-y: auto;
}

.search-results-list {
  padding: 6px;
}

/* Result card */
.search-result {
  display: block;
  text-decoration: none;
  padding: 10px 12px;
  border-radius: 10px;
  transition: background 0.12s ease;
}

.search-result:hover {
  background: var(--chrome-bg-hover);
}

.search-result--focused {
  background: color-mix(in srgb, var(--chrome-accent) 8%, var(--chrome-bg));
}

.search-result-header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.search-result-type {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.55rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 2px 6px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--chrome-accent) 12%, transparent);
  color: var(--chrome-accent);
  flex-shrink: 0;
}

.search-result-title {
  font-size: 0.88rem;
  font-weight: 500;
  color: var(--chrome-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.search-result-snippet {
  font-size: 0.75rem;
  color: var(--chrome-text-dim);
  line-height: 1.5;
  margin: 4px 0 0;
  padding-left: 48px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Highlight */
:deep(.search-hl) {
  background: color-mix(in srgb, #eab308 35%, transparent);
  color: inherit;
  padding: 0 2px;
  border-radius: 2px;
}

/* Empty states */
.search-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
  text-align: center;
  gap: 8px;
}

.search-empty--idle {
  flex-direction: row;
  gap: 8px;
  padding: 32px;
  font-size: 0.82rem;
  color: var(--chrome-text-dim);
}

.search-idle-icon {
  width: 16px;
  height: 16px;
  opacity: 0.4;
}

.search-empty-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--chrome-bg-hover);
  border-radius: 50%;
}

.search-empty-icon svg {
  width: 20px;
  height: 20px;
  color: var(--chrome-text-dim);
}

.search-empty-title {
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--chrome-text);
  margin: 0;
}

.search-empty-hint {
  font-size: 0.8rem;
  color: var(--chrome-text-dim);
  margin: 0;
}

.search-loading-ring {
  width: 20px;
  height: 20px;
  border: 2px solid var(--chrome-border);
  border-top-color: var(--chrome-accent);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Footer */
.search-footer {
  display: flex;
  gap: 16px;
  padding: 10px 16px;
  border-top: 1px solid var(--chrome-border);
  background: color-mix(in srgb, var(--chrome-bg-hover) 40%, var(--chrome-bg));
}

.search-hint {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.6rem;
  color: var(--chrome-text-dim);
  display: flex;
  align-items: center;
  gap: 3px;
}

.search-hint kbd {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  padding: 1px 5px;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.55rem;
  font-weight: 600;
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 4px;
  line-height: 1.5;
}

@media (max-width: 640px) {
  .search-modal {
    max-width: 100%;
    border-radius: 0 0 14px 14px;
    margin: 0 8px;
  }
  .search-backdrop {
    padding-top: 0;
    align-items: flex-start;
    justify-content: center;
  }
}
</style>
