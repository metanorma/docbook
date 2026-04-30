<template>
  <section class="settings-section" style="--delay: 0">
    <h3 class="settings-label">Theme</h3>
    <div class="theme-grid">
      <button
        v-for="t in themes"
        :key="t.value"
        @click="ebookStore.setTheme(t.value)"
        class="theme-card"
        :class="{ 'theme-card--active': currentTheme === t.value }"
        :aria-pressed="currentTheme === t.value"
        :aria-label="t.label + ' theme'"
      >
        <div class="theme-preview" :style="t.previewStyle">
          <span class="theme-preview-text" :style="t.textStyle">Aa</span>
        </div>
        <span class="theme-card-label">{{ t.label }}</span>
      </button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore, type Theme } from '@/stores/ebookStore'

const ebookStore = useEbookStore()
const currentTheme = computed(() => ebookStore.theme)

const themes = [
  { value: 'day' as Theme, label: 'Day', previewStyle: 'background: #fafaf8; border: 1px solid #e2e0dc;', textStyle: 'color: #1a1a1a;' },
  { value: 'sepia' as Theme, label: 'Sepia', previewStyle: 'background: #f4e8d1;', textStyle: 'color: #3e2f23;' },
  { value: 'night' as Theme, label: 'Night', previewStyle: 'background: #1a1a20;', textStyle: 'color: #ddd9d2;' },
  { value: 'oled' as Theme, label: 'OLED', previewStyle: 'background: #000000; border: 1px solid #1e1e1e;', textStyle: 'color: #e8e6e1;' },
]
</script>

<style scoped src="./settings-base.css"></style>
<style scoped>
.theme-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.theme-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 8px 4px;
  border-radius: 10px;
  border: 2px solid transparent;
  transition: border-color 0.15s ease, background 0.15s ease;
  cursor: pointer;
}
.theme-card:hover {
  border-color: var(--chrome-border);
}
.theme-card--active {
  border-color: var(--chrome-accent);
  background: color-mix(in srgb, var(--chrome-accent) 8%, var(--chrome-bg));
}

.theme-preview {
  width: 40px;
  height: 32px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.theme-preview-text {
  font-size: 13px;
  font-weight: 600;
  font-family: Georgia, serif;
}

.theme-card-label {
  font-size: 0.65rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--chrome-text-dim);
}
.theme-card--active .theme-card-label {
  color: var(--chrome-accent);
}
</style>
