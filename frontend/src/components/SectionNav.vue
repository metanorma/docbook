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

      <div class="section-nav-ring-wrap">
        <svg class="section-nav-ring" viewBox="0 0 36 36">
          <circle class="ring-track" cx="18" cy="18" r="15" />
          <circle class="ring-progress" cx="18" cy="18" r="15"
            :stroke-dasharray="circumference"
            :stroke-dashoffset="ringOffset"
          />
        </svg>
        <span class="section-nav-position">{{ currentIndex + 1 }}<span class="section-nav-sep">/</span>{{ sectionIds.length }}</span>
      </div>

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

const circumference = 2 * Math.PI * 15
const ringOffset = computed(() => {
  const total = props.sectionIds.length
  if (total <= 1) return circumference
  const progress = currentIndex.value / (total - 1)
  return circumference * (1 - progress)
})
</script>

<style scoped>
.section-nav {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 4px;
  z-index: 35;
  padding: 4px;
  background: var(--chrome-bg-glass);
  backdrop-filter: blur(8px);
  border: 1px solid var(--chrome-border);
  border-radius: 28px;
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

.section-nav-ring-wrap {
  position: relative;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.section-nav-ring {
  position: absolute;
  inset: 0;
  width: 36px;
  height: 36px;
  transform: rotate(-90deg);
}

.ring-track {
  fill: none;
  stroke: var(--chrome-border);
  stroke-width: 2.5;
}

.ring-progress {
  fill: none;
  stroke: var(--chrome-accent);
  stroke-width: 2.5;
  stroke-linecap: round;
  transition: stroke-dashoffset 0.3s ease;
}

.section-nav-position {
  font-size: 0.55rem;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: var(--chrome-text-dim);
  text-align: center;
  line-height: 1.1;
  z-index: 1;
}

.section-nav-sep {
  opacity: 0.4;
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
