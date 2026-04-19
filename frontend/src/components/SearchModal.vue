<template>
  <Teleport to="body">
    <div
      v-if="uiStore.searchOpen"
      role="dialog"
      aria-label="Search"
      class="fixed inset-0 bg-black/50 z-50 flex items-start justify-center pt-[10vh] transition-opacity duration-200"
      @click.self="uiStore.closeSearch"
    >
      <div class="search-modal w-full max-w-xl rounded-xl shadow-xl overflow-hidden transition-transform duration-200">
        <!-- Search Input -->
        <div class="search-input-row flex items-center gap-3 p-4">
          <svg class="w-5 h-5 flex-shrink-0 search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input
            ref="inputRef"
            v-model="searchQuery"
            type="text"
            class="search-input flex-1 bg-transparent border-none outline-none text-base"
            placeholder="Search headings and content..."
            @keydown="handleKeydown"
          />
          <button
            v-if="searchQuery"
            @click="searchQuery = ''"
            class="search-clear p-1 rounded"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <!-- Search Results -->
        <div class="max-h-80 overflow-y-auto">
          <div v-if="isSearching" class="search-empty p-8 text-center">
            Searching...
          </div>
          <div v-else-if="searchQuery && results.length === 0" class="search-empty p-8 text-center">
            No results found for "{{ searchQuery }}"
          </div>
          <div v-else-if="results.length > 0" class="p-2">
            <a
              v-for="(result, index) in results"
              :key="result.id"
              :href="'#' + result.id"
              @click="selectResult(result)"
              class="search-result flex flex-col gap-1 px-3 py-2 rounded-lg cursor-pointer"
              :class="{ 'search-result-focused': focusedIndex === index }"
              @mouseenter="focusedIndex = index"
            >
              <div class="flex items-center gap-3">
                <span class="search-result-type text-xs px-2 py-0.5 rounded">
                  {{ result.type }}
                </span>
                <span class="flex-1 search-result-title" v-html="highlightMatch(result.title)"></span>
              </div>
              <div v-if="result.snippet" class="search-result-snippet text-xs pl-[3.5rem] line-clamp-2" v-html="highlightMatch(result.snippet)"></div>
            </a>
          </div>
          <div v-else class="search-empty p-8 text-center text-sm">
            Type to search...
          </div>
        </div>

        <!-- Footer hints -->
        <div class="search-footer px-4 py-3">
          <div class="flex gap-4 text-xs">
            <span><kbd class="search-kbd px-1.5 py-0.5 rounded">↑</kbd><kbd class="search-kbd px-1.5 py-0.5 rounded ml-0.5">↓</kbd> Navigate</span>
            <span><kbd class="search-kbd px-1.5 py-0.5 rounded">Enter</kbd> Select</span>
            <span><kbd class="search-kbd px-1.5 py-0.5 rounded">Esc</kbd> Close</span>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, nextTick, inject } from 'vue'
import { useDocumentStore, type TocItem, type MirrorBlockNode, type MirrorTextNode } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { SECTION_TYPES } from '@/utils/typeMetadata'
import FlexSearch from 'flexsearch'

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

// FlexSearch Document index for titles and body text
const index = new (FlexSearch as any).Document({
  document: {
    id: 'id',
    index: ['title', 'body'],
    store: ['id', 'title', 'type', 'body']
  },
  tokenize: 'forward',
  resolution: 9,
  minlength: 2
})

// Map from section id to its body text for snippet extraction
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
      // Not a sectioned node — recurse children
      if (node.content) buildSectionIndex(node.content, parentTitle, parentType)
      return
    }

    const title = node.attrs?.title || parentTitle
    const type = node.type || parentType

    // Collect all text from this node's content (excluding nested sections)
    const bodyText = collectBodyText(node.content)
    const fullText = bodyText.join(' ').trim()

    if (fullText.length > 0) {
      sectionTexts.set(xmlId, fullText)
      index.add({
        id: xmlId,
        title: title,
        type: type,
        body: fullText
      })
    } else if (title) {
      // Section with title but no body text (container section)
      index.add({
        id: xmlId,
        title: title,
        type: type,
        body: ''
      })
    }

    // Recurse into child sections
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
    // Don't descend into nested section-like nodes — those get their own index entry
    if (SECTION_TYPES.has(node.type) && node.attrs?.xml_id) return
    const text = extractTextFromNode(node)
    if (text) texts.push(text)
  })
  return texts
}

function buildTocIndex(items: TocItem[]) {
  items.forEach(item => {
    // Only add if not already indexed from body content
    if (!sectionTexts.has(item.id)) {
      index.add({
        id: item.id,
        title: item.title,
        type: item.type,
        body: ''
      })
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

// Debounced search
let debounceTimer: ReturnType<typeof setTimeout> | null = null
watch(searchQuery, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(search, 150)
})

// Watch for document data changes to rebuild indexes
watch(
  () => documentStore.mirrorDocument,
  () => {
    // Phase 1: Index headings immediately (fast)
    buildHeadingIndex()
    // Phase 2: Background-index body text
    buildBodyIndexLazy()
  },
  { immediate: true }
)

function buildHeadingIndex() {
  sectionTexts.clear()
  // Only index TOC entries for fast heading search
  buildTocIndex(documentStore.sections)
}

function buildBodyIndexLazy() {
  const doc = documentStore.mirrorDocument
  if (!doc?.content) return

  // Use requestIdleCallback to avoid blocking the main thread
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => {
      buildSectionIndex(doc.content!)
      // Also index TOC entries not captured from body
      buildTocIndex(documentStore.sections)
    }, { timeout: 3000 })
  } else {
    setTimeout(() => {
      buildSectionIndex(doc.content!)
      buildTocIndex(documentStore.sections)
    }, 500)
  }
}

onMounted(() => {
  nextTick(() => inputRef.value?.focus())
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
  uiStore.closeSearch()
  searchQuery.value = ''
  results.value = []
}

function highlightMatch(text: string): string {
  if (!searchQuery.value) return text
  const regex = new RegExp(`(${searchQuery.value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi')
  return text.replace(regex, '<mark class="search-highlight rounded px-0.5">$1</mark>')
}
</script>

<style scoped>
.search-modal {
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
}

.search-input-row {
  border-bottom: 1px solid var(--chrome-border);
}

.search-icon {
  color: var(--chrome-text-dim);
}

.search-input {
  color: var(--chrome-text);
}
.search-input::placeholder {
  color: var(--chrome-text-dim);
}

.search-clear {
  color: var(--chrome-text-dim);
}
.search-clear:hover {
  background: var(--chrome-bg-hover);
}

.search-empty {
  color: var(--chrome-text-dim);
}

.search-result {
  text-decoration: none;
  color: var(--chrome-text);
}
.search-result:hover {
  background: var(--chrome-bg-hover);
}

.search-result-focused {
  background: var(--chrome-bg-hover);
}

.search-result-type {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.search-result-title {
  color: var(--chrome-text);
}

.search-result-snippet {
  color: var(--chrome-text-dim);
}

.search-footer {
  border-top: 1px solid var(--chrome-border);
  background: var(--chrome-bg-alt);
  color: var(--chrome-text-dim);
}

.search-kbd {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.search-highlight {
  background: color-mix(in srgb, #eab308 40%, transparent);
  color: inherit;
  padding: 0 2px;
  border-radius: 2px;
}
</style>
