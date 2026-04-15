<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="isSettingsOpen"
        class="fixed inset-0 z-50 flex items-center justify-center"
        @click.self="ebookStore.toggleSettings"
      >
        <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="ebookStore.toggleSettings"></div>

        <div class="settings-panel relative rounded-xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">
          <!-- Header -->
          <div class="settings-header flex items-center justify-between px-6 py-4">
            <h2 class="settings-title text-lg font-semibold">Display Settings</h2>
            <button
              @click="ebookStore.toggleSettings"
              class="settings-close p-1 rounded-lg"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <!-- Content -->
          <div class="px-6 py-5 space-y-6">
            <!-- Reading Mode -->
            <div>
              <label class="settings-label text-sm font-medium mb-3 block">Reading Mode</label>
              <div class="grid grid-cols-4 gap-2">
                <button
                  v-for="mode in readingModes"
                  :key="mode.value"
                  @click="ebookStore.setReadingMode(mode.value)"
                  class="settings-card flex flex-col items-center justify-center p-3 rounded-lg border-2 transition-all"
                  :class="currentReadingMode === mode.value ? 'settings-card-active' : ''"
                >
                  <span class="text-xl mb-1">{{ mode.icon }}</span>
                  <span class="text-xs">{{ mode.label }}</span>
                </button>
              </div>
            </div>

            <!-- Divider -->
            <div class="settings-divider border-t"></div>

            <!-- Theme -->
            <div>
              <label class="settings-label text-sm font-medium mb-3 block">Theme</label>
              <div class="grid grid-cols-4 gap-2">
                <button
                  v-for="t in themes"
                  :key="t.value"
                  @click="ebookStore.setTheme(t.value)"
                  class="settings-card flex flex-col items-center justify-center p-3 rounded-lg border-2 transition-all"
                  :class="currentTheme === t.value ? 'settings-card-active' : ''"
                >
                  <div :class="['w-8 h-8 rounded-full mb-1', t.preview]"></div>
                  <span class="text-xs" :class="t.textClass">{{ t.label }}</span>
                </button>
              </div>
            </div>

            <!-- Divider -->
            <div class="settings-divider border-t"></div>

            <!-- Font Size -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="settings-label text-sm font-medium">Font Size</label>
                <span class="settings-value text-sm">{{ currentFontSize }}px</span>
              </div>
              <input
                type="range"
                min="12"
                max="32"
                :value="currentFontSize"
                @input="ebookStore.setFontSize(Number(($event.target as HTMLInputElement).value))"
                class="settings-slider w-full h-2 rounded-lg appearance-none cursor-pointer"
              />
              <div class="settings-hint flex justify-between text-xs mt-1">
                <span>12px</span>
                <span>32px</span>
              </div>
            </div>

            <!-- Font Weight -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="settings-label text-sm font-medium">Font Weight</label>
                <span class="settings-value text-sm">{{ currentFontWeight }}</span>
              </div>
              <input
                type="range"
                min="300"
                max="700"
                step="100"
                :value="currentFontWeight"
                @input="ebookStore.setFontWeight(Number(($event.target as HTMLInputElement).value))"
                class="settings-slider w-full h-2 rounded-lg appearance-none cursor-pointer"
              />
              <div class="settings-hint flex justify-between text-xs mt-1">
                <span>Light</span>
                <span>Bold</span>
              </div>
            </div>

            <!-- Line Height -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="settings-label text-sm font-medium">Line Height</label>
                <span class="settings-value text-sm">{{ currentLineHeight }}</span>
              </div>
              <input
                type="range"
                min="1.2"
                max="2.0"
                step="0.1"
                :value="currentLineHeight"
                @input="ebookStore.setLineHeight(Number(($event.target as HTMLInputElement).value))"
                class="settings-slider w-full h-2 rounded-lg appearance-none cursor-pointer"
              />
              <div class="settings-hint flex justify-between text-xs mt-1">
                <span>Compact</span>
                <span>Spacious</span>
              </div>
            </div>

            <!-- Margin -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="settings-label text-sm font-medium">Margins</label>
                <span class="settings-value text-sm">{{ currentMargin }}px</span>
              </div>
              <input
                type="range"
                min="16"
                max="96"
                step="8"
                :value="currentMargin"
                @input="ebookStore.setMargin(Number(($event.target as HTMLInputElement).value))"
                class="settings-slider w-full h-2 rounded-lg appearance-none cursor-pointer"
              />
              <div class="settings-hint flex justify-between text-xs mt-1">
                <span>Narrow</span>
                <span>Wide</span>
              </div>
            </div>
          </div>

          <!-- Footer -->
          <div class="settings-footer px-6 py-4">
            <button
              @click="resetToDefaults"
              class="settings-reset w-full py-2 text-sm transition-colors"
            >
              Reset to Defaults
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore, type ReadingMode, type Theme } from '@/composables/useEbookStore'

const ebookStore = useEbookStore()

// Settings open state - use local computed to ensure reactivity
const isSettingsOpen = computed(() => ebookStore.settingsOpen.value)

// Computed properties for template comparisons
const currentReadingMode = computed(() => ebookStore.readingMode.value)
const currentTheme = computed(() => ebookStore.theme.value)
const currentFontSize = computed(() => ebookStore.fontSize.value)
const currentFontWeight = computed(() => ebookStore.fontWeight.value)
const currentLineHeight = computed(() => ebookStore.lineHeight.value.toFixed(1))
const currentMargin = computed(() => ebookStore.margin.value)

const readingModes = [
  { value: 'scroll' as ReadingMode, label: 'Scroll', icon: '📜' },
  { value: 'page' as ReadingMode, label: 'Page', icon: '📄' },
  { value: 'chapter' as ReadingMode, label: 'Chapter', icon: '📑' },
  { value: 'reference' as ReadingMode, label: 'Cards', icon: '💳' },
]

const themes = [
  { value: 'day' as Theme, label: 'Day', preview: 'bg-white border border-gray-300', textClass: 'text-gray-700' },
  { value: 'sepia' as Theme, label: 'Sepia', preview: 'bg-amber-100', textClass: 'text-amber-800' },
  { value: 'night' as Theme, label: 'Night', preview: 'bg-gray-800', textClass: 'text-gray-300' },
  { value: 'oled' as Theme, label: 'OLED', preview: 'bg-black border border-gray-600', textClass: 'text-gray-300' },
]

function resetToDefaults() {
  ebookStore.setFontSize(18)
  ebookStore.setFontWeight(400)
  ebookStore.setLineHeight(1.6)
  ebookStore.setMargin(48)
  ebookStore.setTheme('day')
  ebookStore.setReadingMode('scroll')
}
</script>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active > div:last-child,
.modal-leave-active > div:last-child {
  transition: transform 0.2s ease, opacity 0.2s ease;
}

.modal-enter-from > div:last-child,
.modal-leave-to > div:last-child {
  transform: scale(0.95);
  opacity: 0;
}

.settings-panel {
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
}

.settings-header {
  border-bottom: 1px solid var(--chrome-border);
}

.settings-title {
  color: var(--chrome-text);
}

.settings-close {
  color: var(--chrome-text-dim);
}
.settings-close:hover {
  background: var(--chrome-bg-hover);
}

.settings-label {
  color: var(--chrome-text);
}

.settings-value {
  color: var(--chrome-text-dim);
}

.settings-hint {
  color: var(--chrome-text-dim);
}

.settings-card {
  border-color: var(--chrome-border);
  color: var(--chrome-text-dim);
}
.settings-card:hover {
  border-color: var(--chrome-text-dim);
}
.settings-card-active {
  border-color: var(--chrome-accent);
  background: color-mix(in srgb, var(--chrome-accent) 10%, var(--chrome-bg));
  color: var(--chrome-accent);
}

.settings-divider {
  border-color: var(--chrome-border);
}

.settings-slider {
  background: var(--chrome-bg-hover);
  accent-color: var(--chrome-accent);
}

.settings-footer {
  background: var(--chrome-bg-alt);
  border-top: 1px solid var(--chrome-border);
}

.settings-reset {
  color: var(--chrome-text-dim);
}
.settings-reset:hover {
  color: var(--chrome-text);
}
</style>
