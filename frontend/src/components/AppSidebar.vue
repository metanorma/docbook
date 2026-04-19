<template>
  <aside
    ref="sidebarEl"
    role="navigation"
    aria-label="Table of contents"
    :class="[
      'sidebar-panel fixed top-0 left-0 z-50 w-[280px] h-full overflow-y-auto transition-transform duration-200',
      uiStore.sidebarOpen ? 'translate-x-0' : '-translate-x-full'
    ]"
    @scroll="onSidebarScroll"
  >
    <!-- Sidebar Header -->
    <div class="sidebar-header sticky top-0 p-4 z-10">
      <div class="flex items-center justify-between mb-1">
        <span class="sidebar-title truncate pr-2">
          {{ documentStore.title }}
        </span>
        <button
          @click="uiStore.closeSidebar"
          class="sidebar-btn"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
      <div v-if="documentStore.author" class="sidebar-author truncate mb-3">{{ documentStore.author }}</div>

      <!-- Search button -->
      <button
        @click="uiStore.openSearch"
        class="sidebar-search w-full flex items-center gap-2 px-3 py-1.5 text-sm rounded-md transition-colors"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <span>Search headings...</span>
        <kbd class="sidebar-kbd ml-auto text-xs px-1.5 py-0.5 rounded">/</kbd>
      </button>

      <!-- Font toggle -->
      <div class="flex gap-1 mt-3">
        <button
          @click="setFontFamily('sans')"
          :class="ebookStore.fontFamily.value === 'sans' ? 'sidebar-toggle-active' : 'sidebar-toggle'"
          class="flex-1 py-1 px-2 text-xs rounded-md transition-colors font-sans"
        >
          Sans
        </button>
        <button
          @click="setFontFamily('serif')"
          :class="ebookStore.fontFamily.value === 'serif' ? 'sidebar-toggle-active' : 'sidebar-toggle'"
          class="flex-1 py-1 px-2 text-xs rounded-md transition-colors font-serif"
        >
          Serif
        </button>
      </div>

      <!-- Theme toggle -->
      <button
        @click="cycleTheme"
        class="sidebar-theme-btn w-full flex items-center justify-between mt-2 py-1.5 px-3 text-xs rounded-md transition-colors"
      >
        <span class="flex items-center gap-2">
          <svg v-if="ebookStore.theme.value === 'day' || ebookStore.theme.value === 'sepia'" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
          </svg>
          <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
          </svg>
          <span>{{ themeLabel }}</span>
        </span>
      </button>
    </div>

    <!-- TOC -->
    <nav class="p-3 relative">
      <ul class="space-y-0.5">
        <TocTreeItem
          v-for="item in documentStore.sections"
          :key="item.id"
          :item="item"
          :depth="1"
        />
      </ul>
      <!-- Follow focus button -->
      <button
        v-if="!uiStore.tocFollowFocus"
        @click="followFocus"
        class="follow-focus-btn"
      >
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/></svg>
        Follow active section
      </button>
    </nav>

    <!-- Bookmarks -->
    <div v-if="bookmarks.bookmarks.value.length > 0" class="sidebar-section">
      <div class="sidebar-section-title">
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/></svg>
        Bookmarks
        <kbd class="sidebar-kbd text-xs px-1 py-0.5 rounded ml-auto">b</kbd>
      </div>
      <ul class="space-y-0.5">
        <li v-for="bm in bookmarks.bookmarks.value" :key="bm.id" class="bookmark-item">
          <a @click.prevent="navigateToId(bm.sectionId)" class="bookmark-link" :title="bm.snippet">
            {{ bm.title }}
          </a>
          <button @click="bookmarks.remove(bm.sectionId)" class="bookmark-remove" title="Remove bookmark">
            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </li>
      </ul>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { computed, ref, inject } from 'vue'
import { useDocumentStore } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useEbookStore } from '@/composables/useEbookStore'
import { useBookmarks, type Bookmark } from '@/composables/useBookmarks'
import TocTreeItem from '@/components/TocTreeItem.vue'

const documentStore = useDocumentStore()
const uiStore = useUiStore()
const ebookStore = useEbookStore()
const sidebarEl = ref<HTMLElement | null>(null)

const bookmarks = inject<ReturnType<typeof useBookmarks>>('bookmarks')!
const navigateToId = inject<(id: string) => void>('navigateToId', () => {})

const themeLabel = computed(() => {
  switch (ebookStore.theme.value) {
    case 'day': return 'Day'
    case 'sepia': return 'Sepia'
    case 'night': return 'Night'
    case 'oled': return 'OLED'
  }
})

function cycleTheme() { ebookStore.cycleTheme() }

function setFontFamily(font: 'sans' | 'serif') {
  ebookStore.setFontFamily(font as any)
}

function onSidebarScroll() {
  // User manually scrolled the TOC — disable auto-follow
  if (uiStore.tocFollowFocus) {
    uiStore.setTocFollowFocus(false)
  }
}

function followFocus() {
  uiStore.setTocFollowFocus(true)
}
</script>

<style scoped>
.sidebar-panel {
  background: var(--chrome-bg-alt);
  border-right: 1px solid var(--chrome-border);
  transition: transform 0.2s ease, background 0.2s ease;
}

.sidebar-header {
  background: var(--chrome-bg-alt);
  border-bottom: 1px solid var(--chrome-border);
}

.sidebar-title {
  font-weight: 700;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--chrome-text-dim);
}

.sidebar-author {
  font-size: 0.7rem;
  color: var(--chrome-text-dim);
  opacity: 0.7;
}

.sidebar-btn {
  padding: 0.25rem;
  border-radius: 0.25rem;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease;
}

.sidebar-btn:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.sidebar-search {
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  color: var(--chrome-text-dim);
}

.sidebar-search:hover {
  background: var(--chrome-bg-hover);
}

.sidebar-kbd {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.sidebar-toggle {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.sidebar-toggle-active {
  background: var(--chrome-accent);
  color: #ffffff;
}

.sidebar-theme-btn {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.sidebar-theme-btn:hover {
  background: var(--chrome-bg);
}

.follow-focus-btn {
  position: sticky;
  bottom: 8px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  font-size: 0.7rem;
  font-weight: 500;
  border-radius: 999px;
  background: var(--chrome-accent);
  color: #fff;
  border: none;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  transition: opacity 0.15s ease;
  margin-top: 8px;
}
.follow-focus-btn:hover {
  opacity: 0.9;
}

/* Bookmarks */
.sidebar-section {
  padding: 12px 16px 8px;
  border-top: 1px solid var(--chrome-border);
}

.sidebar-section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--chrome-text-dim);
  margin-bottom: 8px;
}

.bookmark-item {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 6px;
  border-radius: 4px;
  transition: background 0.15s ease;
}

.bookmark-item:hover {
  background: var(--chrome-bg-hover);
}

.bookmark-link {
  flex: 1;
  font-size: 0.8rem;
  color: var(--chrome-text);
  cursor: pointer;
  text-decoration: none;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.bookmark-link:hover {
  color: var(--chrome-accent);
}

.bookmark-remove {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 4px;
  color: var(--chrome-text-dim);
  opacity: 0;
  transition: opacity 0.15s ease, background 0.15s ease;
}

.bookmark-item:hover .bookmark-remove {
  opacity: 1;
}

.bookmark-remove:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}
</style>
