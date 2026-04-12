<template>
  <div class="ebook-topbar" :class="{ 'ebook-topbar--with-sidebar': sidebarOpen }">
    <div class="flex items-center justify-between px-4 py-2">
      <!-- Left: Menu button -->
      <button
        @click="$emit('toggle-toc')"
        class="p-2 rounded-lg hover:bg-black/10 dark:hover:bg-white/10 text-gray-700 dark:text-gray-300 transition-colors"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
        </svg>
      </button>

      <!-- Center: Title -->
      <div class="flex-1 text-center px-4">
        <h1 class="text-sm font-medium text-gray-700 dark:text-gray-300 truncate">
          {{ title }}
        </h1>
      </div>

      <!-- Right: Actions -->
      <div class="flex items-center gap-1">
        <!-- Font settings -->
        <button
          @click="$emit('toggle-settings')"
          class="p-2 rounded-lg hover:bg-black/10 dark:hover:bg-white/10 text-gray-700 dark:text-gray-300 transition-colors"
          title="Display settings"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7"/>
          </svg>
        </button>

        <!-- Theme toggle -->
        <button
          @click="cycleTheme"
          class="p-2 rounded-lg hover:bg-black/10 dark:hover:bg-white/10 text-gray-700 dark:text-gray-300 transition-colors"
          :title="`Theme: ${currentTheme}`"
        >
          <svg v-if="currentTheme === 'day'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
          </svg>
          <svg v-else-if="currentTheme === 'sepia'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
          </svg>
          <svg v-else-if="currentTheme === 'night'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
          </svg>
          <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
          </svg>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore, type Theme } from '@/composables/useEbookStore'

defineProps<{
  title?: string
  sidebarOpen?: boolean
}>()

defineEmits<{
  'toggle-toc': []
  'toggle-settings': []
}>()

const ebookStore = useEbookStore()
const currentTheme = computed(() => ebookStore.theme.value)

const themeOrder: Theme[] = ['day', 'sepia', 'night', 'oled']

function cycleTheme() {
  const currentIndex = themeOrder.indexOf(ebookStore.theme.value)
  const nextIndex = (currentIndex + 1) % themeOrder.length
  ebookStore.setTheme(themeOrder[nextIndex])
}
</script>

<style scoped>
.ebook-topbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 30;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  transition: left 0.2s ease;
}

:global(.dark) .ebook-topbar {
  background: rgba(17, 24, 39, 0.9);
  border-bottom-color: rgba(255, 255, 255, 0.1);
}

.ebook-topbar--with-sidebar {
  left: 280px;
}

@media (max-width: 1023px) {
  .ebook-topbar--with-sidebar {
    left: 0;
  }
}

.ebook-topbar button {
  min-width: 44px;
  min-height: 44px;
}
</style>
