<template>
  <Teleport to="body">
    <div
      v-if="uiStore.searchOpen"
      class="fixed inset-0 bg-black/50 z-50 flex items-start justify-center pt-[10vh] transition-opacity duration-200"
      @click.self="uiStore.closeSearch"
    >
      <div class="w-full max-w-xl bg-white dark:bg-gray-800 rounded-xl shadow-xl overflow-hidden transition-transform duration-200">
        <!-- Search Input -->
        <div class="flex items-center gap-3 p-4 border-b border-gray-200 dark:border-gray-700">
          <svg class="w-5 h-5 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input
            ref="inputRef"
            v-model="searchQuery"
            type="text"
            class="flex-1 bg-transparent border-none outline-none text-gray-900 dark:text-gray-100 placeholder-gray-400 text-base"
            placeholder="Search headings and content..."
            @keydown="handleKeydown"
          />
          <button
            v-if="searchQuery"
            @click="searchQuery = ''"
            class="p-1 rounded hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-400"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <!-- Search Results -->
        <div class="max-h-80 overflow-y-auto">
          <div v-if="isSearching" class="p-8 text-center text-gray-500">
            Searching...
          </div>
          <div v-else-if="searchQuery && results.length === 0" class="p-8 text-center text-gray-500">
            No results found for "{{ searchQuery }}"
          </div>
          <div v-else-if="results.length > 0" class="p-2">
            <a
              v-for="(result, index) in results"
              :key="result.id"
              :href="'#' + result.id"
              @click="selectResult(result)"
              class="flex flex-col gap-1 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer"
              :class="{ 'bg-gray-100 dark:bg-gray-700': focusedIndex === index }"
              @mouseenter="focusedIndex = index"
            >
              <div class="flex items-center gap-3">
                <span class="text-xs px-2 py-0.5 rounded bg-gray-200 dark:bg-gray-600 text-gray-600 dark:text-gray-300">
                  {{ result.type }}
                </span>
                <span class="flex-1 text-gray-900 dark:text-gray-100" v-html="highlightMatch(result.title)"></span>
              </div>
              <div v-if="result.snippet" class="text-xs text-gray-500 dark:text-gray-400 pl-[3.5rem] line-clamp-2" v-html="highlightMatch(result.snippet)"></div>
            </a>
          </div>
          <div v-else class="p-8 text-center text-gray-400 text-sm">
            Type to search...
          </div>
        </div>

        <!-- Footer hints -->
        <div class="px-4 py-3 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900">
          <div class="flex gap-4 text-xs text-gray-400">
            <span><kbd class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded text-gray-600 dark:text-gray-300">↑</kbd><kbd class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded text-gray-600 dark:text-gray-300 ml-0.5">↓</kbd> Navigate</span>
            <span><kbd class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded text-gray-600 dark:text-gray-300">Enter</kbd> Select</span>
            <span><kbd class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded text-gray-600 dark:text-gray-300">Esc</kbd> Close</span>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, nextTick } from 'vue'
import { useDocumentStore, type TocItem, type ContentBlock } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import FlexSearch from 'flexsearch'

const documentStore = useDocumentStore()
const uiStore = useUiStore()

interface SearchResult {
  id: string
  title: string
  type: 'chapter' | 'appendix' | 'part' | 'section' | 'glossary' | 'bibliography' | 'index' | 'reference' | 'preface'
  children?: TocItem[]
  snippet?: string
}

const searchQuery = ref('')
const results = ref<SearchResult[]>([])
const isSearching = ref(false)
const focusedIndex = ref(0)
const inputRef = ref<HTMLInputElement | null>(null)

// FlexSearch Document index for titles
const index = new (FlexSearch as any).Document({
  document: {
    id: 'id',
    index: ['title'],
    store: ['id', 'title', 'type']
  },
  tokenize: 'forward',
  resolution: 9
})

function buildIndexes() {
  const sections = documentStore.sections
  addToIndex(sections)
}

function addToIndex(items: TocItem[]) {
  items.forEach(item => {
    index.add({
      id: item.id,
      title: item.title,
      type: item.type
    })
    if (item.children && item.children.length > 0) {
      addToIndex(item.children)
    }
  })
}

function extractTextFromBlocks(blocks: ContentBlock[]): string {
  return blocks.map(block => {
    let text = block.text || ''
    if (block.children) {
      text += ' ' + extractTextFromBlocks(block.children)
    }
    return text
  }).join(' ')
}

function searchContent(query: string): SearchResult[] {
  const content = documentStore.content
  const searchResults: SearchResult[] = []
  const lowerQuery = query.toLowerCase()

  for (const [id, sectionContent] of Object.entries(content)) {
    const text = extractTextFromBlocks(sectionContent.blocks || []).toLowerCase()
    if (text.includes(lowerQuery)) {
      // Find the snippet around the match
      const matchPos = text.indexOf(lowerQuery)
      const start = Math.max(0, matchPos - 50)
      const end = Math.min(text.length, matchPos + query.length + 100)
      let snippet = extractTextFromBlocks(sectionContent.blocks || []).substring(start, end)
      if (start > 0) snippet = '...' + snippet
      if (end < text.length) snippet = snippet + '...'

      // Get section info from TOC
      const section = findSection(documentStore.sections, id)
      searchResults.push({
        id,
        title: section?.title || id,
        type: (section?.type || 'section') as SearchResult['type'],
        snippet
      })
    }
  }
  return searchResults
}

function findSection(items: TocItem[], id: string): TocItem | null {
  for (const item of items) {
    if (item.id === id) return item
    if (item.children && item.children.length > 0) {
      const found = findSection(item.children, id)
      if (found) return found
    }
  }
  return null
}

function search() {
  if (!searchQuery.value.trim()) {
    results.value = []
    return
  }

  isSearching.value = true

  // Search titles with FlexSearch
  const searchResults = index.search(searchQuery.value, { limit: 30, enrich: true })

  const titleResults: Map<string, TocItem> = new Map()
  const seen = new Set<string>()

  if (Array.isArray(searchResults)) {
    searchResults.forEach((field: { result: Array<{ id: string; doc?: TocItem }> }) => {
      if (field.result && Array.isArray(field.result)) {
        field.result.forEach((r: { id: string; doc?: TocItem }) => {
          if (r.doc && !seen.has(r.id)) {
            seen.add(r.id)
            titleResults.set(r.id, r.doc)
          }
        })
      }
    })
  }

  // Search full content
  const contentResults = searchContent(searchQuery.value)

  // Combine results, prioritizing title matches
  const combined: SearchResult[] = []

  // First add title matches
  titleResults.forEach((tocItem) => {
    combined.push({
      id: tocItem.id,
      title: tocItem.title,
      type: tocItem.type,
      children: tocItem.children
    })
  })

  // Then add content-only matches
  contentResults.forEach((cr) => {
    if (!seen.has(cr.id)) {
      seen.add(cr.id)
      combined.push(cr)
    }
  })

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
  () => documentStore.documentData,
  () => {
    buildIndexes()
  },
  { immediate: true }
)

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
  // Scroll to section and close search
  const element = document.getElementById(result.id)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' })
    uiStore.closeSearch()
    searchQuery.value = ''
    results.value = []
  }
}

function highlightMatch(text: string): string {
  if (!searchQuery.value) return text
  const regex = new RegExp(`(${searchQuery.value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi')
  return text.replace(regex, '<mark class="bg-yellow-200 dark:bg-yellow-600 rounded px-0.5">$1</mark>')
}
</script>
