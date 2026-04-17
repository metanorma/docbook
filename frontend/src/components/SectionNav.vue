<template>
  <Transition name="section-nav-fade">
    <div v-if="visible && sectionIds.length > 0" class="section-nav">
      <button
        v-if="hasPrev"
        class="section-nav-btn"
        aria-label="Previous section"
        @click="$emit('navigate', sectionIds[currentIndex - 1])"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/>
        </svg>
      </button>
      <span v-if="sectionIds.length > 0" class="section-nav-position">
        {{ currentIndex + 1 }} / {{ sectionIds.length }}
      </span>
      <button
        v-if="hasNext"
        class="section-nav-btn"
        aria-label="Next section"
        @click="$emit('navigate', sectionIds[currentIndex + 1])"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7"/>
        </svg>
      </button>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  sectionIds: string[]
  activeIndex: number
  visible: boolean
}>()

defineEmits<{
  navigate: [id: string]
}>()

const currentIndex = computed(() => Math.max(0, props.activeIndex))
const hasPrev = computed(() => currentIndex.value > 0)
const hasNext = computed(() => currentIndex.value < props.sectionIds.length - 1)
</script>

<style scoped>
.section-nav {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 6px;
  z-index: 35;
  padding: 4px;
  background: var(--chrome-bg-glass);
  backdrop-filter: blur(8px);
  border: 1px solid var(--chrome-border);
  border-radius: 24px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.section-nav-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease;
}

.section-nav-btn:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.section-nav-position {
  font-size: 0.7rem;
  font-variant-numeric: tabular-nums;
  color: var(--chrome-text-dim);
  padding: 0 4px;
  min-width: 48px;
  text-align: center;
}

.section-nav-fade-enter-active,
.section-nav-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.section-nav-fade-enter-from,
.section-nav-fade-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(12px);
}
</style>
