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
        ref="panelEl"
        role="dialog"
        aria-label="Display settings"
        aria-modal="true"
        class="fixed top-0 right-0 bottom-0 z-50 w-[340px] max-w-[90vw] settings-panel overflow-y-auto"
      >
        <!-- Header -->
        <div class="settings-header">
          <div class="settings-header-inner">
            <div class="settings-header-dot"></div>
            <h2 class="settings-title">Display</h2>
          </div>
          <button @click="close" class="settings-close" title="Close settings">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <!-- Sections with staggered animation -->
        <div class="settings-body">
          <ThemeSelector />
          <TypographyControls />
          <ReadingControls />
          <DisplayToggles />

          <!-- Reading Stats -->
          <section v-if="readingStats" class="settings-section" style="--delay: 4">
            <h3 class="settings-label">Reading Stats</h3>
            <div class="stats-grid">
              <div class="stat-card">
                <span class="stat-value">{{ readingStats.sectionsReadCount.value }}</span>
                <span class="stat-label">Sections read</span>
              </div>
              <div class="stat-card">
                <span class="stat-value">{{ readingStats.readPercentage.value }}%</span>
                <span class="stat-label">Progress</span>
              </div>
              <div class="stat-card">
                <span class="stat-value">{{ readingStats.estimatedReadingTime.value }}m</span>
                <span class="stat-label">Est. time</span>
              </div>
              <div class="stat-card">
                <span class="stat-value">{{ readingStats.activeReadingMinutes.value }}m</span>
                <span class="stat-label">Active</span>
              </div>
            </div>
          </section>

          <!-- Sync -->
          <section class="settings-section" style="--delay: 5">
            <h3 class="settings-label">Backup</h3>
            <div class="settings-row">
              <span class="settings-sublabel">Export</span>
              <button @click="cloudSync.push()" class="sync-btn" :disabled="cloudSync.syncing.value">
                {{ cloudSync.syncing.value ? 'Saving...' : 'Export settings' }}
              </button>
            </div>
            <div class="settings-row">
              <span class="settings-sublabel">Import</span>
              <button @click="cloudSync.pull()" class="sync-btn" :disabled="cloudSync.syncing.value">
                {{ cloudSync.syncing.value ? 'Loading...' : 'Import settings' }}
              </button>
            </div>
            <div v-if="cloudSync.syncError.value" class="sync-error">
              {{ cloudSync.syncError.value }}
            </div>
            <div v-if="cloudSync.lastSyncAt.value" class="sync-time">
              Last sync: {{ new Date(cloudSync.lastSyncAt.value).toLocaleTimeString() }}
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
import { computed, inject, ref, watch, nextTick } from 'vue'
import { useEbookStore } from '@/stores/ebookStore'
import { useReadingStats } from '@/composables/useReadingStats'
import { useCloudSync } from '@/composables/useCloudSync'
import { useDocumentStore } from '@/stores/documentStore'
import { useFocusTrap } from '@/composables/useFocusTrap'
import ThemeSelector from '@/components/settings/ThemeSelector.vue'
import TypographyControls from '@/components/settings/TypographyControls.vue'
import ReadingControls from '@/components/settings/ReadingControls.vue'
import DisplayToggles from '@/components/settings/DisplayToggles.vue'

const ebookStore = useEbookStore()
const documentStore = useDocumentStore()
const readingStats = inject<ReturnType<typeof useReadingStats>>('readingStats')

const cloudSync = useCloudSync(documentStore.title)
const panelEl = ref<HTMLElement | null>(null)

const focusTrap = useFocusTrap(panelEl, { onEscape: () => close() })

const isSettingsOpen = computed(() => ebookStore.settingsOpen)

watch(isSettingsOpen, (open) => {
  if (open) {
    nextTick(() => focusTrap.activate())
  } else {
    focusTrap.deactivate()
  }
})

function close() {
  ebookStore.toggleSettings()
}

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
  ebookStore.setReadingMode('scroll')
  ebookStore.setRefCardMode(false)
}
</script>

<style scoped src="./settings/settings-base.css"></style>
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
  padding: 14px 18px;
  border-bottom: 1px solid var(--chrome-border);
  position: sticky;
  top: 0;
  z-index: 1;
  background: var(--chrome-bg);
}

.settings-header-inner {
  display: flex;
  align-items: center;
  gap: 8px;
}

.settings-header-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--chrome-accent);
}

.settings-title {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--chrome-text);
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

.settings-close svg { width: 18px; height: 18px; }

.settings-close:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.settings-body {
  padding: 8px 0;
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

/* Reading stats */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
}

.stat-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 10px 6px;
  border-radius: 8px;
  background: var(--chrome-bg-hover);
  border: 1px solid color-mix(in srgb, var(--chrome-border) 60%, transparent);
}

.stat-value {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--chrome-accent);
  font-variant-numeric: tabular-nums;
}

.stat-label {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.6rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--chrome-text-dim);
  margin-top: 2px;
}

/* Sync */
.sync-btn {
  padding: 6px 12px;
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 6px;
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
  transition: background 0.15s ease;
}

.sync-btn:hover:not(:disabled) {
  background: var(--chrome-accent);
  color: #fff;
}

.sync-btn:disabled {
  opacity: 0.5;
  cursor: default;
}

.sync-error {
  font-size: 0.75rem;
  color: #ef4444;
  margin-top: 4px;
}

.sync-time {
  font-size: 0.7rem;
  color: var(--chrome-text-dim);
  margin-top: 4px;
}

/* Mobile: full-screen settings panel */
@media (max-width: 640px) {
  .settings-panel {
    width: 100% !important;
    max-width: 100% !important;
  }
}
</style>
