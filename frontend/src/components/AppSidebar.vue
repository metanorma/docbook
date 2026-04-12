<template>
  <aside
    :class="[
      'fixed top-0 left-0 z-50 w-[280px] h-full bg-gray-50 dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 overflow-y-auto transition-transform duration-200',
      uiStore.sidebarOpen ? 'translate-x-0' : '-translate-x-full'
    ]"
  >
    <!-- Sidebar Header -->
    <div class="sticky top-0 bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 p-4 z-10">
      <div class="flex items-center justify-between mb-3">
        <span class="font-bold text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400 truncate pr-2">
          {{ documentStore.title }}
        </span>
        <button
          @click="uiStore.closeSidebar"
          class="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-600 dark:text-gray-300"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Search button -->
      <button
        @click="uiStore.openSearch"
        class="w-full flex items-center gap-2 px-3 py-1.5 text-sm bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600 text-gray-500 dark:text-gray-400 transition-colors"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <span>Search headings...</span>
        <kbd class="ml-auto text-xs bg-gray-100 dark:bg-gray-600 px-1.5 py-0.5 rounded">/</kbd>
      </button>

      <!-- Font toggle -->
      <div class="flex gap-1 mt-3">
        <button
          @click="setFontFamily('sans')"
          :class="uiStore.fontFamily === 'sans' ? 'bg-blue-500 text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'"
          class="flex-1 py-1 px-2 text-xs rounded-md transition-colors font-sans"
        >
          Sans
        </button>
        <button
          @click="setFontFamily('serif')"
          :class="uiStore.fontFamily === 'serif' ? 'bg-blue-500 text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'"
          class="flex-1 py-1 px-2 text-xs rounded-md transition-colors font-serif"
        >
          Serif
        </button>
      </div>

      <!-- Theme toggle -->
      <button
        @click="cycleTheme"
        class="w-full flex items-center justify-between mt-2 py-1.5 px-3 text-xs bg-gray-200 dark:bg-gray-700 rounded-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors text-gray-700 dark:text-gray-300"
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
    <nav class="p-3">
      <ul class="space-y-0.5">
        <TocTreeItem
          v-for="item in documentStore.sections"
          :key="item.id"
          :item="item"
          :depth="1"
        />
      </ul>
    </nav>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useDocumentStore } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { useEbookStore, type Theme } from '@/composables/useEbookStore'
import TocTreeItem from '@/components/TocTreeItem.vue'

const documentStore = useDocumentStore()
const uiStore = useUiStore()
const ebookStore = useEbookStore()

const themeOrder: Theme[] = ['day', 'sepia', 'night', 'oled']

const themeLabel = computed(() => {
  switch (ebookStore.theme.value) {
    case 'day': return 'Day'
    case 'sepia': return 'Sepia'
    case 'night': return 'Night'
    case 'oled': return 'OLED'
  }
})

function cycleTheme() {
  const currentIndex = themeOrder.indexOf(ebookStore.theme.value)
  const nextIndex = (currentIndex + 1) % themeOrder.length
  ebookStore.setTheme(themeOrder[nextIndex])
}

function setFontFamily(font: 'sans' | 'serif') {
  uiStore.setFontFamily(font)
}
</script>
