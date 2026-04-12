<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="isSettingsOpen"
        class="fixed inset-0 z-50 flex items-center justify-center"
        @click.self="ebookStore.toggleSettings"
      >
        <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="ebookStore.toggleSettings"></div>

        <div class="relative bg-white dark:bg-gray-900 rounded-xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">
          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Display Settings</h2>
            <button
              @click="ebookStore.toggleSettings"
              class="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500"
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
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 block">Reading Mode</label>
              <div class="grid grid-cols-4 gap-2">
                <button
                  v-for="mode in readingModes"
                  :key="mode.value"
                  @click="ebookStore.setReadingMode(mode.value)"
                  :class="[
                    'flex flex-col items-center justify-center p-3 rounded-lg border-2 transition-all',
                    currentReadingMode === mode.value
                      ? 'border-cyan-500 bg-cyan-50 dark:bg-cyan-900/30 text-cyan-700 dark:text-cyan-300'
                      : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600 text-gray-600 dark:text-gray-400'
                  ]"
                >
                  <span class="text-xl mb-1">{{ mode.icon }}</span>
                  <span class="text-xs">{{ mode.label }}</span>
                </button>
              </div>
            </div>

            <!-- Divider -->
            <div class="border-t border-gray-200 dark:border-gray-700"></div>

            <!-- Theme -->
            <div>
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 block">Theme</label>
              <div class="grid grid-cols-4 gap-2">
                <button
                  v-for="t in themes"
                  :key="t.value"
                  @click="ebookStore.setTheme(t.value)"
                  :class="[
                    'flex flex-col items-center justify-center p-3 rounded-lg border-2 transition-all',
                    currentTheme === t.value
                      ? 'border-cyan-500 bg-cyan-50 dark:bg-cyan-900/30'
                      : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                  ]"
                >
                  <div :class="['w-8 h-8 rounded-full mb-1', t.preview]"></div>
                  <span class="text-xs" :class="t.textClass">{{ t.label }}</span>
                </button>
              </div>
            </div>

            <!-- Divider -->
            <div class="border-t border-gray-200 dark:border-gray-700"></div>

            <!-- Font Size -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Font Size</label>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{ currentFontSize }}px</span>
              </div>
              <input
                type="range"
                min="12"
                max="32"
                :value="currentFontSize"
                @input="ebookStore.setFontSize(Number(($event.target as HTMLInputElement).value))"
                class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-cyan-500"
              />
              <div class="flex justify-between text-xs text-gray-400 mt-1">
                <span>12px</span>
                <span>32px</span>
              </div>
            </div>

            <!-- Font Weight -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Font Weight</label>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{ currentFontWeight }}</span>
              </div>
              <input
                type="range"
                min="300"
                max="700"
                step="100"
                :value="currentFontWeight"
                @input="ebookStore.setFontWeight(Number(($event.target as HTMLInputElement).value))"
                class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-cyan-500"
              />
              <div class="flex justify-between text-xs text-gray-400 mt-1">
                <span>Light</span>
                <span>Bold</span>
              </div>
            </div>

            <!-- Line Height -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Line Height</label>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{ currentLineHeight }}</span>
              </div>
              <input
                type="range"
                min="1.2"
                max="2.0"
                step="0.1"
                :value="currentLineHeight"
                @input="ebookStore.setLineHeight(Number(($event.target as HTMLInputElement).value))"
                class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-cyan-500"
              />
              <div class="flex justify-between text-xs text-gray-400 mt-1">
                <span>Compact</span>
                <span>Spacious</span>
              </div>
            </div>

            <!-- Margin -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Margins</label>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{ currentMargin }}px</span>
              </div>
              <input
                type="range"
                min="16"
                max="96"
                step="8"
                :value="currentMargin"
                @input="ebookStore.setMargin(Number(($event.target as HTMLInputElement).value))"
                class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-cyan-500"
              />
              <div class="flex justify-between text-xs text-gray-400 mt-1">
                <span>Narrow</span>
                <span>Wide</span>
              </div>
            </div>
          </div>

          <!-- Footer -->
          <div class="px-6 py-4 bg-gray-50 dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700">
            <button
              @click="resetToDefaults"
              class="w-full py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
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
</style>
