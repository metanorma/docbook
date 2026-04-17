<template>
  <Teleport to="body">
    <!-- Backdrop -->
    <Transition name="settings-backdrop">
      <div v-if="isSettingsOpen" class="fixed inset-0 z-50 bg-black/40 backdrop-blur-[2px]" @click="close"></div>
    </Transition>

    <!-- Panel -->
    <Transition name="settings-panel">
      <div
        v-if="isSettingsOpen"
        role="dialog"
        aria-label="Display settings"
        class="fixed top-0 right-0 bottom-0 z-50 w-[340px] max-w-[90vw] settings-panel overflow-y-auto"
      >
        <!-- Header -->
        <div class="settings-header">
          <h2 class="settings-title">Display</h2>
          <button @click="close" class="settings-close" title="Close settings">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <!-- Sections with staggered animation -->
        <div class="settings-body">
          <!-- Theme -->
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

          <!-- Typography -->
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

          <!-- Layout -->
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
              <button
                @click="ebookStore.toggleFocusMode()"
                class="toggle-switch"
                :class="{ 'toggle-switch--on': currentFocusMode }"
                role="switch"
                :aria-checked="currentFocusMode"
                aria-label="Focus mode"
              >
                <span class="toggle-switch-thumb"></span>
              </button>
            </div>
          </section>

          <!-- Advanced -->
          <section class="settings-section" style="--delay: 3">
            <h3 class="settings-label">Advanced</h3>

            <!-- Hyphenation -->
            <div class="settings-row">
              <span class="settings-sublabel">Hyphens</span>
              <button
                @click="ebookStore.setHyphenation(!currentHyphenation)"
                class="toggle-switch"
                :class="{ 'toggle-switch--on': currentHyphenation }"
                role="switch"
                :aria-checked="currentHyphenation"
                aria-label="Hyphenation"
              >
                <span class="toggle-switch-thumb"></span>
              </button>
            </div>

            <!-- Progress Bar -->
            <div class="settings-row">
              <span class="settings-sublabel">Progress</span>
              <button
                @click="ebookStore.setShowProgress(!currentShowProgress)"
                class="toggle-switch"
                :class="{ 'toggle-switch--on': currentShowProgress }"
                role="switch"
                :aria-checked="currentShowProgress"
                aria-label="Progress bar"
              >
                <span class="toggle-switch-thumb"></span>
              </button>
            </div>
          </section>

          <!-- Reset -->
          <div class="settings-footer">
            <button @click="resetToDefaults" class="settings-reset">Reset to Defaults</button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore, type Theme, type FontFamily, type ContentWidth, type LineHeight, type TextAlignment } from '@/composables/useEbookStore'

const ebookStore = useEbookStore()

const isSettingsOpen = computed(() => ebookStore.settingsOpen.value)
const currentTheme = computed(() => ebookStore.theme.value)
const currentFontSize = computed(() => ebookStore.fontSize.value)
const currentFontFamily = computed(() => ebookStore.fontFamily.value)
const currentContentWidth = computed(() => ebookStore.contentWidth.value)
const currentLineHeight = computed(() => ebookStore.lineHeight.value)
const currentTextAlignment = computed(() => ebookStore.textAlignment.value)
const currentHyphenation = computed(() => ebookStore.hyphenation.value)
const currentFocusMode = computed(() => ebookStore.focusMode.value)
const currentShowProgress = computed(() => ebookStore.showProgress.value)

function close() {
  ebookStore.toggleSettings()
}

const themes = [
  { value: 'day' as Theme, label: 'Day', previewStyle: 'background: #fafaf8; border: 1px solid #e2e0dc;', textStyle: 'color: #1a1a1a;' },
  { value: 'sepia' as Theme, label: 'Sepia', previewStyle: 'background: #f4e8d1;', textStyle: 'color: #3e2f23;' },
  { value: 'night' as Theme, label: 'Night', previewStyle: 'background: #1a1a20;', textStyle: 'color: #ddd9d2;' },
  { value: 'oled' as Theme, label: 'OLED', previewStyle: 'background: #000000; border: 1px solid #1e1e1e;', textStyle: 'color: #e8e6e1;' },
]

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

const widthOptions = [
  { value: 'narrow' as ContentWidth, label: 'Narrow', barWidth: '30%' },
  { value: 'default' as ContentWidth, label: 'Default', barWidth: '55%' },
  { value: 'wide' as ContentWidth, label: 'Wide', barWidth: '90%' },
]

function resetToDefaults() {
  ebookStore.setFontSize(18)
  ebookStore.setFontFamily('sans')
  ebookStore.setContentWidth('default')
  ebookStore.setTheme('day')
  ebookStore.setLineHeight('comfortable')
  ebookStore.setTextAlignment('left')
  ebookStore.setHyphenation(false)
  ebookStore.setFocusMode(false)
  ebookStore.setShowProgress(true)
}
</script>

<style scoped>
/* Panel backdrop */
.settings-backdrop-enter-active,
.settings-backdrop-leave-active {
  transition: opacity 0.25s ease;
}
.settings-backdrop-enter-from,
.settings-backdrop-leave-to {
  opacity: 0;
}

/* Panel slide */
.settings-panel-enter-active {
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.settings-panel-leave-active {
  transition: transform 0.2s ease-in;
}
.settings-panel-enter-from,
.settings-panel-leave-to {
  transform: translateX(100%);
}

/* Panel chrome */
.settings-panel {
  background: var(--chrome-bg);
  border-left: 1px solid var(--chrome-border);
  box-shadow: -8px 0 32px rgba(0, 0, 0, 0.12);
}

.settings-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--chrome-border);
  position: sticky;
  top: 0;
  z-index: 1;
  background: var(--chrome-bg);
}

.settings-title {
  font-size: 0.8rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--chrome-text-dim);
}

.settings-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease;
}
.settings-close:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.settings-body {
  padding: 8px 0;
}

/* Staggered section entrance */
.settings-section {
  padding: 16px 20px;
  border-bottom: 1px solid var(--chrome-border);
  animation: sectionFadeIn 0.3s ease backwards;
  animation-delay: calc(var(--delay, 0) * 60ms);
}

@keyframes sectionFadeIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.settings-label {
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--chrome-accent);
  margin-bottom: 12px;
}

.settings-sublabel {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--chrome-text);
  white-space: nowrap;
}

.settings-value {
  font-size: 0.75rem;
  font-variant-numeric: tabular-nums;
  color: var(--chrome-text-dim);
}

/* Rows */
.settings-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}
.settings-row:last-child {
  margin-bottom: 0;
}

.settings-row-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex: 1;
  min-width: 0;
}

/* Theme cards */
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

/* Slider */
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

/* Toggle group (for font face, line height, alignment) */
.toggle-group {
  display: flex;
  gap: 4px;
  background: var(--chrome-bg-hover);
  padding: 3px;
  border-radius: 8px;
}

.toggle-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 6px;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease, box-shadow 0.15s ease;
  cursor: pointer;
  white-space: nowrap;
}

.toggle-btn:hover {
  color: var(--chrome-text);
}

.toggle-btn--active {
  background: var(--chrome-bg);
  color: var(--chrome-accent);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.toggle-btn--wide {
  padding: 6px 8px;
  font-size: 0.7rem;
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

/* Width presets */
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

/* Toggle switch */
.toggle-switch {
  position: relative;
  width: 40px;
  height: 22px;
  border-radius: 11px;
  background: var(--chrome-bg-hover);
  border: 1px solid var(--chrome-border);
  cursor: pointer;
  transition: background 0.2s ease, border-color 0.2s ease;
  flex-shrink: 0;
}

.toggle-switch--on {
  background: var(--chrome-accent);
  border-color: var(--chrome-accent);
}

.toggle-switch-thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--chrome-text);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
  transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.toggle-switch--on .toggle-switch-thumb {
  transform: translateX(18px);
  background: #ffffff;
}

/* Footer */
.settings-footer {
  padding: 16px 20px;
}

.settings-reset {
  width: 100%;
  padding: 8px;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--chrome-text-dim);
  border-radius: 8px;
  border: 1px solid var(--chrome-border);
  transition: background 0.15s ease, color 0.15s ease;
}
.settings-reset:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

/* Mobile: full-screen settings panel */
@media (max-width: 640px) {
  .settings-panel {
    width: 100% !important;
    max-width: 100% !important;
  }
}
</style>
