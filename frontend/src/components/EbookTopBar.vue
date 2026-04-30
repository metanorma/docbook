<template>
  <header class="ebook-topbar" role="banner" :class="{ 'ebook-topbar--with-sidebar': sidebarOpen }">
    <div class="topbar-inner">
      <!-- Left: Back to library + Menu -->
      <div class="topbar-left">
        <button
          v-if="showBackToLibrary"
          @click="$emit('back-to-library')"
          class="topbar-btn topbar-tooltip"
          aria-label="Back to library"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
          </svg>
          <span class="topbar-tooltip-text">Back to library</span>
        </button>
        <button
          @click="$emit('toggle-toc')"
          class="topbar-btn topbar-tooltip"
          aria-label="Toggle table of contents"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
          </svg>
          <span class="topbar-tooltip-text">Contents</span>
        </button>
      </div>

      <!-- Center: Title + chapter context -->
      <div class="topbar-center">
        <div class="topbar-title-group">
          <h1 class="topbar-title">{{ title }}</h1>
          <span v-if="readPct > 0" class="topbar-progress" :title="`${readPct}% read`">{{ readPct }}%</span>
        </div>
        <Transition name="topbar-chapter">
          <p v-if="currentChapter" :key="currentChapter" class="topbar-chapter">{{ currentChapter }}</p>
        </Transition>
      </div>

      <!-- Right: Actions -->
      <div class="topbar-right">
        <button
          @click="$emit('toggle-settings')"
          class="topbar-btn topbar-tooltip"
          aria-label="Display settings"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7"/>
          </svg>
          <span class="topbar-tooltip-text">Display settings</span>
        </button>

        <button
          @click="cycleTheme"
          class="topbar-btn topbar-tooltip"
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
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore } from '@/stores/ebookStore'

defineProps<{
  title?: string
  currentChapter?: string
  sidebarOpen?: boolean
  showBackToLibrary?: boolean
  readPct?: number
}>()

defineEmits<{
  'toggle-toc': []
  'toggle-settings': []
  'back-to-library': []
}>()

const ebookStore = useEbookStore()
const currentTheme = computed(() => ebookStore.theme)

function cycleTheme() { ebookStore.cycleTheme() }
</script>

<style scoped>
.ebook-topbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 30;
  background: var(--chrome-bg-glass);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--chrome-border);
  transition: left 0.2s ease, background 0.2s ease;
}

.ebook-topbar--with-sidebar {
  left: 280px;
}

@media (max-width: 1023px) {
  .ebook-topbar--with-sidebar {
    left: 0;
  }
}

.topbar-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;
  height: 48px;
}

.topbar-left,
.topbar-right {
  display: flex;
  align-items: center;
  gap: 2px;
}

.topbar-center {
  flex: 1;
  text-align: center;
  min-width: 0;
  padding: 0 12px;
}

.topbar-title-group {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.topbar-title {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--chrome-text);
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 280px;
}

.topbar-progress {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.6rem;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: 999px;
  background: color-mix(in srgb, var(--chrome-accent) 12%, var(--chrome-bg-hover));
  color: var(--chrome-accent);
  letter-spacing: 0.03em;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
  flex-shrink: 0;
}

.topbar-chapter {
  font-size: 0.7rem;
  font-weight: 400;
  color: var(--chrome-text-dim);
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 320px;
  margin-left: auto;
  margin-right: auto;
}

.topbar-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 40px;
  min-height: 40px;
  padding: 8px;
  border-radius: 8px;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease;
}

.topbar-btn:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

/* Tooltip */
.topbar-tooltip {
  position: relative;
}
.topbar-tooltip .topbar-tooltip-text {
  position: absolute;
  bottom: -30px;
  left: 50%;
  transform: translateX(-50%) scale(0.9);
  padding: 4px 8px;
  font-size: 0.6rem;
  font-weight: 500;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  white-space: nowrap;
  border-radius: 6px;
  background: var(--chrome-text);
  color: var(--chrome-bg);
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.15s ease, transform 0.15s ease;
  z-index: 50;
}
.topbar-tooltip:hover .topbar-tooltip-text {
  opacity: 1;
  transform: translateX(-50%) scale(1);
}

/* Chapter transition */
.topbar-chapter-enter-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}
.topbar-chapter-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
  position: absolute;
  left: 0;
  right: 0;
}
.topbar-chapter-enter-from {
  opacity: 0;
  transform: translateY(4px);
}
.topbar-chapter-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

/* Mobile */
@media (max-width: 640px) {
  .topbar-title { max-width: 120px; }
  .topbar-chapter { display: none; }
}
</style>
