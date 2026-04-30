<template>
  <aside
    ref="sidebarEl"
    role="navigation"
    aria-label="Table of contents"
    :aria-hidden="!uiStore.sidebarOpen"
    :inert="!uiStore.sidebarOpen"
    :class="[
      'sidebar',
      uiStore.sidebarOpen ? 'sidebar--open' : 'sidebar--closed'
    ]"
    @scroll="onSidebarScroll"
  >
    <!-- Header -->
    <div class="sidebar-header">
      <div class="sidebar-header-top">
        <div class="sidebar-title-group">
          <span class="sidebar-title">{{ documentStore.title }}</span>
          <span v-if="documentStore.author" class="sidebar-author">{{ documentStore.author }}</span>
        </div>
        <button @click="uiStore.closeSidebar" class="sidebar-close-btn" aria-label="Close sidebar">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Search trigger -->
      <button @click="uiStore.openSearch" class="sidebar-search-btn">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <span>Search...</span>
        <kbd class="sidebar-kbd">/</kbd>
      </button>

      <!-- TOC filter -->
      <div class="sidebar-filter">
        <svg class="sidebar-filter-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4h18M3 8h12M3 12h6"/>
        </svg>
        <input v-model="tocFilter" type="text" class="sidebar-filter-input" placeholder="Filter sections..." />
        <button v-if="tocFilter" @click="tocFilter = ''" class="sidebar-filter-clear">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Progress ring -->
      <div v-if="readingStats && readingStats.totalSections > 0" class="sidebar-progress">
        <svg class="sidebar-progress-ring" viewBox="0 0 48 48" width="44" height="44">
          <circle cx="24" cy="24" r="20" fill="none" stroke="var(--chrome-border)" stroke-width="2.5" />
          <circle
            cx="24" cy="24" r="20" fill="none"
            stroke="var(--chrome-accent)"
            stroke-width="2.5"
            stroke-linecap="round"
            :stroke-dasharray="progressCircumference"
            :stroke-dashoffset="progressOffset"
            transform="rotate(-90 24 24)"
            class="sidebar-progress-arc"
          />
          <text x="24" y="24" text-anchor="middle" dominant-baseline="central"
                font-size="10" font-weight="700" fill="var(--chrome-text)"
                font-family="'JetBrains Mono', ui-monospace, monospace">
            {{ readingStats.readPercentage.value }}%
          </text>
        </svg>
        <div class="sidebar-progress-info">
          <span class="sidebar-progress-label">{{ readingStats.sectionsReadCount.value }} of {{ readingStats.totalSections }} sections read</span>
          <span v-if="readingStats.estimatedReadingTime.value > 0" class="sidebar-progress-time">~{{ readingStats.estimatedReadingTime.value }} min remaining</span>
        </div>
      </div>
    </div>

    <!-- TOC Tree -->
    <nav class="sidebar-toc">
      <div v-if="tocFilter && filteredSections.length === 0" class="sidebar-toc-empty">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="sidebar-toc-empty-icon">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <span>No matching sections</span>
      </div>
      <ul v-else class="sidebar-toc-list">
        <TocTreeItem
          v-for="item in (tocFilter ? filteredSections : documentStore.sections)"
          :key="item.id"
          :item="item"
          :depth="1"
          :force-open="!!tocFilter"
        />
      </ul>
    </nav>

    <!-- Follow focus -->
    <div class="sidebar-toc-actions">
      <button v-if="!uiStore.tocFollowFocus" @click="followFocus" class="follow-focus-btn">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
        </svg>
        Follow current section
      </button>
    </div>

    <!-- Bookmarks -->
    <div v-if="bookmarks.bookmarks.value.length > 0" class="sidebar-bookmarks">
      <div class="sidebar-bookmarks-title">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/>
        </svg>
        Bookmarks
        <kbd class="sidebar-kbd sidebar-kbd--sm">b</kbd>
      </div>
      <ul class="sidebar-bookmarks-list">
        <li v-for="bm in bookmarks.bookmarks.value" :key="bm.id" class="bookmark-item">
          <a @click.prevent="navigateToId(bm.sectionId)" class="bookmark-link" :title="bm.snippet">
            {{ bm.title }}
          </a>
          <button @click="bookmarks.remove(bm.sectionId)" class="bookmark-remove" title="Remove bookmark">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </li>
      </ul>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { computed, ref, inject } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useEbookStore } from '@/stores/ebookStore'
import { useBookmarks } from '@/composables/useBookmarks'
import { useReadingStats } from '@/composables/useReadingStats'
import TocTreeItem from '@/components/TocTreeItem.vue'

const documentStore = useDocumentStore()
const uiStore = useUiStore()
const ebookStore = useEbookStore()
const sidebarEl = ref<HTMLElement | null>(null)
const tocFilter = ref('')

const bookmarks = inject<ReturnType<typeof useBookmarks>>('bookmarks')!
const navigateToId = inject<(id: string) => void>('navigateToId', () => {})
const readingStats = inject<ReturnType<typeof useReadingStats> | null>('readingStats', null)

const progressCircumference = computed(() => 2 * Math.PI * 20)
const progressOffset = computed(() => {
  if (!readingStats) return progressCircumference.value
  const pct = readingStats.readPercentage.value / 100
  return progressCircumference.value * (1 - pct)
})

const filteredSections = computed(() => {
  const q = tocFilter.value.trim().toLowerCase()
  if (!q) return documentStore.sections

  function filterTree(items: TocItem[]): TocItem[] {
    const result: TocItem[] = []
    for (const item of items) {
      const titleMatch = item.title.toLowerCase().includes(q)
      const filteredChildren = item.children ? filterTree(item.children) : []
      if (titleMatch || filteredChildren.length > 0) {
        result.push({
          ...item,
          children: titleMatch ? item.children : filteredChildren,
        })
      }
    }
    return result
  }
  return filterTree(documentStore.sections)
})

function onSidebarScroll() {
  if (uiStore.tocFollowFocus) {
    uiStore.setTocFollowFocus(false)
  }
}

function followFocus() {
  uiStore.setTocFollowFocus(true)
}
</script>

<style scoped>
.sidebar {
  position: fixed;
  top: 0;
  left: 0;
  z-index: 50;
  width: 280px;
  height: 100%;
  overflow-y: auto;
  overflow-x: hidden;
  background: var(--chrome-bg-alt);
  border-right: 1px solid var(--chrome-border);
  display: flex;
  flex-direction: column;
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), background 0.2s ease;
}

.sidebar--closed {
  transform: translateX(-100%);
}

.sidebar--open {
  transform: translateX(0);
}

/* Header */
.sidebar-header {
  flex-shrink: 0;
  padding: 16px;
  border-bottom: 1px solid var(--chrome-border);
  background: var(--chrome-bg-alt);
  position: sticky;
  top: 0;
  z-index: 2;
}

.sidebar-header-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 12px;
}

.sidebar-title-group {
  min-width: 0;
}

.sidebar-title {
  display: block;
  font-family: 'DM Sans', system-ui, sans-serif;
  font-weight: 700;
  font-size: 0.8rem;
  color: var(--chrome-text);
  line-height: 1.3;
  letter-spacing: -0.01em;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.sidebar-author {
  display: block;
  font-size: 0.7rem;
  color: var(--chrome-text-dim);
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sidebar-close-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  border-radius: 8px;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease;
}

.sidebar-close-btn svg { width: 18px; height: 18px; }
.sidebar-close-btn:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

/* Search button */
.sidebar-search-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 0.8rem;
  font-family: 'DM Sans', system-ui, sans-serif;
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 8px;
  color: var(--chrome-text-dim);
  cursor: pointer;
  transition: border-color 0.15s ease, background 0.15s ease;
}

.sidebar-search-btn svg { width: 14px; height: 14px; flex-shrink: 0; }
.sidebar-search-btn:hover {
  border-color: var(--chrome-accent);
  background: var(--chrome-bg-hover);
}

.sidebar-kbd {
  margin-left: auto;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.55rem;
  font-weight: 600;
  padding: 2px 5px;
  border-radius: 4px;
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
  border: 1px solid var(--chrome-border);
}

.sidebar-kbd--sm {
  font-size: 0.5rem;
  padding: 1px 4px;
}

/* Filter */
.sidebar-filter {
  position: relative;
  margin-top: 8px;
}

.sidebar-filter-icon {
  position: absolute;
  left: 8px;
  top: 50%;
  transform: translateY(-50%);
  width: 14px;
  height: 14px;
  color: var(--chrome-text-dim);
  pointer-events: none;
}

.sidebar-filter-input {
  width: 100%;
  padding: 6px 28px 6px 28px;
  font-size: 0.78rem;
  font-family: 'DM Sans', system-ui, sans-serif;
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 6px;
  color: var(--chrome-text);
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.sidebar-filter-input::placeholder { color: var(--chrome-text-dim); }
.sidebar-filter-input:focus {
  border-color: var(--chrome-accent);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--chrome-accent) 12%, transparent);
}

.sidebar-filter-clear {
  position: absolute;
  right: 6px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  align-items: center;
  padding: 2px;
  color: var(--chrome-text-dim);
  border-radius: 3px;
  transition: color 0.15s ease;
}
.sidebar-filter-clear svg { width: 12px; height: 12px; }
.sidebar-filter-clear:hover { color: var(--chrome-text); }

/* Progress ring */
.sidebar-progress {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
  padding: 10px 12px;
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 8px;
}

.sidebar-progress-ring { flex-shrink: 0; }

.sidebar-progress-arc {
  transition: stroke-dashoffset 0.5s ease;
}

.sidebar-progress-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.sidebar-progress-label {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--chrome-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sidebar-progress-time {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.62rem;
  color: var(--chrome-text-dim);
  letter-spacing: 0.01em;
}

/* TOC */
.sidebar-toc {
  flex: 1;
  overflow-y: auto;
  padding: 8px 10px;
}

.sidebar-toc-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.sidebar-toc-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 32px 16px;
  text-align: center;
  font-size: 0.8rem;
  color: var(--chrome-text-dim);
}

.sidebar-toc-empty-icon {
  width: 28px;
  height: 28px;
  opacity: 0.4;
}

.sidebar-toc-actions {
  padding: 8px 16px;
}

.follow-focus-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  width: 100%;
  padding: 8px 12px;
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.72rem;
  font-weight: 500;
  border-radius: 8px;
  background: color-mix(in srgb, var(--chrome-accent) 10%, transparent);
  color: var(--chrome-accent);
  border: 1px solid color-mix(in srgb, var(--chrome-accent) 20%, transparent);
  cursor: pointer;
  transition: background 0.15s ease, border-color 0.15s ease;
}

.follow-focus-btn svg { width: 14px; height: 14px; }
.follow-focus-btn:hover {
  background: color-mix(in srgb, var(--chrome-accent) 15%, transparent);
  border-color: color-mix(in srgb, var(--chrome-accent) 30%, transparent);
}

/* Bookmarks */
.sidebar-bookmarks {
  padding: 12px 16px;
  border-top: 1px solid var(--chrome-border);
}

.sidebar-bookmarks-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.68rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--chrome-text-dim);
  margin-bottom: 8px;
}

.sidebar-bookmarks-title svg { width: 14px; height: 14px; }

.sidebar-bookmarks-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.bookmark-item {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 6px;
  border-radius: 6px;
  transition: background 0.15s ease;
}

.bookmark-item:hover { background: var(--chrome-bg-hover); }

.bookmark-link {
  flex: 1;
  font-size: 0.78rem;
  color: var(--chrome-text);
  cursor: pointer;
  text-decoration: none;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: color 0.15s ease;
}

.bookmark-link:hover { color: var(--chrome-accent); }

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

.bookmark-remove svg { width: 12px; height: 12px; }
.bookmark-item:hover .bookmark-remove { opacity: 1; }
.bookmark-remove:hover { background: var(--chrome-bg-hover); color: var(--chrome-text); }

@media (max-width: 640px) {
  .sidebar { width: 100%; }
}
</style>
