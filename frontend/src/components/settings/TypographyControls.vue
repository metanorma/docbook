<template>
  <section class="settings-section" style="--delay: 1">
    <h3 class="settings-label">Typography</h3>

    <!-- Font Size -->
    <div class="settings-row">
      <div class="settings-row-header">
        <span class="settings-sublabel">Size</span>
        <span class="settings-value">{{ currentFontSize }}px</span>
      </div>
      <div class="slider-track">
        <span class="slider-label-sm">A</span>
        <input
          type="range"
          min="12"
          max="32"
          step="1"
          :value="currentFontSize"
          @input="ebookStore.setFontSize(Number(($event.target as HTMLInputElement).value))"
          class="slider-input"
          aria-label="Font size"
          :aria-valuenow="currentFontSize"
          aria-valuemin="12"
          aria-valuemax="32"
        />
        <span class="slider-label-lg">A</span>
      </div>
    </div>

    <!-- Typeface -->
    <div class="settings-row">
      <span class="settings-sublabel">Face</span>
      <div class="toggle-group">
        <button
          v-for="f in fontFamilies"
          :key="f.value"
          @click="ebookStore.setFontFamily(f.value)"
          class="toggle-btn"
          :class="{ 'toggle-btn--active': currentFontFamily === f.value }"
          :style="{ fontFamily: f.css }"
          :aria-pressed="currentFontFamily === f.value"
        >{{ f.label }}</button>
      </div>
    </div>

    <!-- Line Height -->
    <div class="settings-row">
      <span class="settings-sublabel">Leading</span>
      <div class="toggle-group">
        <button
          v-for="lh in lineHeightOptions"
          :key="lh.value"
          @click="ebookStore.setLineHeight(lh.value)"
          class="toggle-btn toggle-btn--wide"
          :class="{ 'toggle-btn--active': currentLineHeight === lh.value }"
        >
          <span class="leading-preview">
            <span :style="{ lineHeight: lh.numeric }">A</span>
          </span>
          {{ lh.label }}
        </button>
      </div>
    </div>

    <!-- Text Alignment -->
    <div class="settings-row">
      <span class="settings-sublabel">Align</span>
      <div class="toggle-group">
        <button
          v-for="al in alignmentOptions"
          :key="al.value"
          @click="ebookStore.setTextAlignment(al.value)"
          class="toggle-btn"
          :class="{ 'toggle-btn--active': currentTextAlignment === al.value }"
        >
          <svg class="w-4 h-4" viewBox="0 0 16 16" fill="currentColor">
            <rect :x="al.value === 'justify' ? 0 : 0" y="1" :width="al.value === 'justify' ? 16 : 10" height="1.5" rx="0.5"/>
            <rect :x="al.value === 'justify' ? 0 : 0" y="5" :width="al.value === 'justify' ? 16 : 12" height="1.5" rx="0.5"/>
            <rect :x="al.value === 'justify' ? 0 : 0" y="9" :width="al.value === 'justify' ? 16 : 10" height="1.5" rx="0.5"/>
            <rect :x="al.value === 'justify' ? 0 : 0" y="13" :width="al.value === 'justify' ? 16 : 8" height="1.5" rx="0.5"/>
          </svg>
          {{ al.label }}
        </button>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore, type FontFamily, type LineHeight, type TextAlignment } from '@/stores/ebookStore'

const ebookStore = useEbookStore()

const currentFontSize = computed(() => ebookStore.fontSize)
const currentFontFamily = computed(() => ebookStore.fontFamily)
const currentLineHeight = computed(() => ebookStore.lineHeight)
const currentTextAlignment = computed(() => ebookStore.textAlignment)

const fontFamilies = [
  { value: 'sans' as FontFamily, label: 'Sans', css: 'system-ui, -apple-system, sans-serif' },
  { value: 'serif' as FontFamily, label: 'Serif', css: 'Georgia, "Times New Roman", serif' },
]

const lineHeightOptions = [
  { value: 'compact' as LineHeight, label: 'Tight', numeric: '1.0' },
  { value: 'comfortable' as LineHeight, label: 'Comfy', numeric: '1.3' },
  { value: 'relaxed' as LineHeight, label: 'Open', numeric: '1.6' },
  { value: 'spacious' as LineHeight, label: 'Airy', numeric: '2.0' },
]

const alignmentOptions = [
  { value: 'left' as TextAlignment, label: 'Left' },
  { value: 'justify' as TextAlignment, label: 'Justify' },
]
</script>

<style scoped src="./settings-base.css"></style>
<style scoped>
.slider-track {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.slider-label-sm {
  font-size: 11px;
  font-weight: 700;
  color: var(--chrome-text-dim);
}

.slider-label-lg {
  font-size: 17px;
  font-weight: 700;
  color: var(--chrome-text-dim);
}

.slider-input {
  flex: 1;
  -webkit-appearance: none;
  appearance: none;
  height: 4px;
  border-radius: 2px;
  background: var(--chrome-bg-hover);
  outline: none;
  cursor: pointer;
}

.slider-input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--chrome-accent);
  border: 3px solid var(--chrome-bg);
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: transform 0.1s ease;
}

.slider-input::-webkit-slider-thumb:hover {
  transform: scale(1.15);
}

.slider-input::-moz-range-thumb {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--chrome-accent);
  border: 3px solid var(--chrome-bg);
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.2);
  cursor: pointer;
}

.leading-preview {
  display: inline-flex;
  flex-direction: column;
  width: 14px;
  overflow: hidden;
}

.leading-preview span {
  display: block;
  font-size: 8px;
  font-weight: 700;
}
</style>
