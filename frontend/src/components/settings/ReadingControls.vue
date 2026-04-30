<template>
  <section class="settings-section" style="--delay: 2">
    <h3 class="settings-label">Layout</h3>

    <!-- Content Width -->
    <div class="settings-row">
      <span class="settings-sublabel">Width</span>
      <div class="width-presets">
        <button
          v-for="w in widthOptions"
          :key="w.value"
          @click="ebookStore.setContentWidth(w.value)"
          class="width-card"
          :class="{ 'width-card--active': currentContentWidth === w.value }"
        >
          <div class="width-bar-container">
            <div class="width-bar" :style="{ width: w.barWidth }"></div>
          </div>
          <span class="width-label">{{ w.label }}</span>
        </button>
      </div>
    </div>

    <!-- Focus Mode -->
    <div class="settings-row">
      <span class="settings-sublabel">Focus</span>
      <ToggleSwitch
        :model-value="currentFocusMode"
        @update:model-value="ebookStore.setFocusMode($event)"
        label="Focus mode"
      />
    </div>

    <!-- Reading Mode -->
    <div class="settings-row">
      <span class="settings-sublabel">Mode</span>
      <div class="toggle-group">
        <button
          @click="ebookStore.setReadingMode('scroll')"
          class="toggle-btn"
          :class="{ 'toggle-btn--active': currentReadingMode === 'scroll' }"
          :aria-pressed="currentReadingMode === 'scroll'"
        >
          <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M2 2h12M2 6h12M2 10h12M2 14h10"/>
          </svg>
          Scroll
        </button>
        <button
          @click="ebookStore.setReadingMode('paged')"
          class="toggle-btn"
          :class="{ 'toggle-btn--active': currentReadingMode === 'paged' }"
          :aria-pressed="currentReadingMode === 'paged'"
        >
          <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="2" width="12" height="12" rx="1"/>
            <line x1="8" y1="2" x2="8" y2="14"/>
          </svg>
          Pages
        </button>
      </div>
    </div>

    <!-- Reference Card Mode -->
    <div class="settings-row">
      <span class="settings-sublabel">Ref Cards</span>
      <ToggleSwitch
        :model-value="currentRefCardMode"
        @update:model-value="ebookStore.setRefCardMode($event)"
        label="Reference card swipe mode"
      />
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore, type ContentWidth } from '@/stores/ebookStore'
import ToggleSwitch from '@/components/ui/ToggleSwitch.vue'

const ebookStore = useEbookStore()

const currentContentWidth = computed(() => ebookStore.contentWidth)
const currentFocusMode = computed(() => ebookStore.focusMode)
const currentReadingMode = computed(() => ebookStore.readingMode)
const currentRefCardMode = computed(() => ebookStore.refCardMode)

const widthOptions = [
  { value: 'narrow' as ContentWidth, label: 'Narrow', barWidth: '30%' },
  { value: 'default' as ContentWidth, label: 'Default', barWidth: '55%' },
  { value: 'wide' as ContentWidth, label: 'Wide', barWidth: '90%' },
]
</script>

<style scoped src="./settings-base.css"></style>
<style scoped>
.width-presets {
  display: flex;
  gap: 6px;
  flex: 1;
}

.width-card {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 10px 6px 8px;
  border-radius: 8px;
  border: 2px solid transparent;
  transition: border-color 0.15s ease, background 0.15s ease;
  cursor: pointer;
}
.width-card:hover {
  border-color: var(--chrome-border);
}
.width-card--active {
  border-color: var(--chrome-accent);
  background: color-mix(in srgb, var(--chrome-accent) 8%, var(--chrome-bg));
}

.width-bar-container {
  width: 100%;
  height: 3px;
  background: var(--chrome-bg-hover);
  border-radius: 2px;
  overflow: hidden;
}

.width-bar {
  height: 100%;
  background: var(--chrome-text-dim);
  border-radius: 2px;
  transition: width 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.width-card--active .width-bar {
  background: var(--chrome-accent);
}

.width-label {
  font-size: 0.65rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--chrome-text-dim);
}
.width-card--active .width-label {
  color: var(--chrome-accent);
}
</style>
