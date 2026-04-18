<template>
  <div class="ref-card-container" v-if="entries.length > 0">
    <div class="ref-card-header">
      <span class="ref-card-counter">{{ currentIndex + 1 }} / {{ entries.length }}</span>
      <div class="ref-card-nav">
        <button @click="prev" :disabled="currentIndex <= 0" class="ref-card-btn" title="Previous entry">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        </button>
        <button @click="next" :disabled="currentIndex >= entries.length - 1" class="ref-card-btn" title="Next entry">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
        </button>
      </div>
    </div>

    <Transition :name="transitionName" mode="out-in">
      <div
        :key="currentEntry.attrs?.xml_id || currentIndex"
        class="ref-card"
        @touchstart="onTouchStart"
        @touchmove="onTouchMove"
        @touchend="onTouchEnd"
      >
        <MirrorRenderer :blocks="[currentEntry]" />
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import MirrorRenderer from './MirrorRenderer.vue'
import type { MirrorBlockNode } from '@/stores/documentStore'

const props = defineProps<{
  entries: MirrorBlockNode[]
}>()

const currentIndex = ref(0)
const transitionName = ref('slide-right')

const currentEntry = computed(() => props.entries[currentIndex.value] || props.entries[0])

function next() {
  if (currentIndex.value < props.entries.length - 1) {
    transitionName.value = 'slide-left'
    currentIndex.value++
  }
}

function prev() {
  if (currentIndex.value > 0) {
    transitionName.value = 'slide-right'
    currentIndex.value--
  }
}

// Touch/swipe support
let touchStartX = 0
let touchStartY = 0

function onTouchStart(e: TouchEvent) {
  touchStartX = e.touches[0].clientX
  touchStartY = e.touches[0].clientY
}

function onTouchMove(e: TouchEvent) {
  // Prevent default scroll during horizontal swipe
  const dx = Math.abs(e.touches[0].clientX - touchStartX)
  const dy = Math.abs(e.touches[0].clientY - touchStartY)
  if (dx > dy) {
    e.preventDefault()
  }
}

function onTouchEnd(e: TouchEvent) {
  const dx = e.changedTouches[0].clientX - touchStartX
  const dy = e.changedTouches[0].clientY - touchStartY
  if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 50) {
    if (dx < 0) next()
    else prev()
  }
}
</script>

<style scoped>
.ref-card-container {
  max-width: 800px;
  margin: 0 auto;
}

.ref-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
  margin-bottom: 8px;
  border-bottom: 1px solid var(--ebook-border);
}

.ref-card-counter {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--ebook-text-muted);
  font-variant-numeric: tabular-nums;
}

.ref-card-nav {
  display: flex;
  gap: 4px;
}

.ref-card-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  color: var(--ebook-text);
  transition: background 0.15s ease;
}

.ref-card-btn:hover:not(:disabled) {
  background: var(--chrome-bg-hover);
}

.ref-card-btn:disabled {
  opacity: 0.3;
  cursor: default;
}

.ref-card {
  background: var(--ebook-bg-secondary);
  border: 1px solid var(--ebook-border);
  border-radius: 12px;
  padding: 24px;
  min-height: 300px;
  touch-action: pan-y;
}

/* Slide transitions */
.slide-left-enter-active,
.slide-left-leave-active,
.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform 0.2s ease, opacity 0.2s ease;
}

.slide-left-enter-from {
  transform: translateX(40px);
  opacity: 0;
}

.slide-left-leave-to {
  transform: translateX(-40px);
  opacity: 0;
}

.slide-right-enter-from {
  transform: translateX(-40px);
  opacity: 0;
}

.slide-right-leave-to {
  transform: translateX(40px);
  opacity: 0;
}
</style>
