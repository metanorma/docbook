<template>
  <Teleport to="body">
    <Transition name="help-overlay">
      <div v-if="visible" ref="helpEl" class="help-backdrop" role="dialog" aria-label="Keyboard shortcuts" aria-modal="true" @click.self="close">
        <div class="help-card">
          <div class="help-header">
            <div class="help-header-inner">
              <div class="help-header-dot"></div>
              <h2 class="help-title">Shortcuts</h2>
            </div>
            <button class="help-close" @click="close">
              <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <div class="help-body">
            <div class="help-group">
              <h3 class="help-group-title">Navigation</h3>
              <div class="help-row" v-for="s in navigation" :key="s.key">
                <kbd class="help-key">{{ s.key }}</kbd>
                <span class="help-desc">{{ s.desc }}</span>
              </div>
            </div>

            <div class="help-divider"></div>

            <div class="help-group">
              <h3 class="help-group-title">Display</h3>
              <div class="help-row" v-for="s in display" :key="s.key">
                <kbd class="help-key">{{ s.key }}</kbd>
                <span class="help-desc">{{ s.desc }}</span>
              </div>
            </div>
          </div>

          <div class="help-footer">
            Press <kbd class="help-key help-key--sm">?</kbd> or <kbd class="help-key help-key--sm">Esc</kbd> to close
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { useFocusTrap } from '@/composables/useFocusTrap'

const props = defineProps<{
  visible: boolean
}>()

const emit = defineEmits<{
  close: []
}>()

const helpEl = ref<HTMLElement | null>(null)
const focusTrap = useFocusTrap(helpEl, { onEscape: () => close() })

watch(() => props.visible, (v) => {
  if (v) nextTick(() => focusTrap.activate())
  else focusTrap.deactivate()
})

function close() {
  emit('close')
}

const navigation = [
  { key: 'j', desc: 'Next section' },
  { key: 'k', desc: 'Previous section' },
  { key: '/', desc: 'Open search' },
  { key: 't', desc: 'Toggle sidebar' },
  { key: 'b', desc: 'Bookmark section' },
  { key: '→ / Space', desc: 'Next page (paged)' },
  { key: '←', desc: 'Previous page (paged)' },
]

const display = [
  { key: 's', desc: 'Toggle settings' },
  { key: 'f', desc: 'Focus mode' },
  { key: 'r', desc: 'Reading ruler' },
  { key: 'P', desc: 'TTS play / pause' },
  { key: 'p', desc: 'TTS stop' },
  { key: '?', desc: 'This help' },
  { key: 'Esc', desc: 'Close panels' },
]
</script>

<style scoped>
.help-backdrop {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.45);
  backdrop-filter: blur(4px);
}

.help-card {
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 14px;
  width: 400px;
  max-width: 90vw;
  overflow: hidden;
  box-shadow:
    0 4px 12px rgba(0, 0, 0, 0.08),
    0 24px 64px rgba(0, 0, 0, 0.16);
}

.help-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  border-bottom: 1px solid var(--chrome-border);
}

.help-header-inner {
  display: flex;
  align-items: center;
  gap: 8px;
}

.help-header-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--chrome-accent);
}

.help-title {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--chrome-text);
  margin: 0;
}

.help-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease, color 0.15s ease;
}

.help-close svg { width: 16px; height: 16px; }
.help-close:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.help-body {
  display: flex;
  gap: 0;
}

.help-group {
  flex: 1;
  padding: 14px 18px;
}

.help-divider {
  width: 1px;
  background: var(--chrome-border);
}

.help-group-title {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.55rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--chrome-accent);
  margin: 0 0 10px;
}

.help-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 4px 0;
}

.help-key {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 32px;
  height: 24px;
  padding: 0 7px;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.65rem;
  font-weight: 600;
  border-radius: 5px;
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
  border: 1px solid var(--chrome-border);
  box-shadow: 0 1px 0 var(--chrome-border);
}

.help-key--sm {
  min-width: 24px;
  height: 18px;
  font-size: 0.55rem;
  padding: 0 4px;
}

.help-desc {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.78rem;
  color: var(--chrome-text-dim);
}

.help-footer {
  padding: 10px 18px;
  border-top: 1px solid var(--chrome-border);
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.72rem;
  color: var(--chrome-text-dim);
  text-align: center;
}

/* Animations */
.help-overlay-enter-active {
  transition: opacity 0.2s ease;
}
.help-overlay-enter-active .help-card {
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.2s ease;
}
.help-overlay-leave-active {
  transition: opacity 0.15s ease;
}
.help-overlay-leave-active .help-card {
  transition: transform 0.15s ease, opacity 0.15s ease;
}
.help-overlay-enter-from {
  opacity: 0;
}
.help-overlay-enter-from .help-card {
  transform: scale(0.92);
  opacity: 0;
}
.help-overlay-leave-to {
  opacity: 0;
}
.help-overlay-leave-to .help-card {
  transform: scale(0.96);
  opacity: 0;
}

@media (max-width: 480px) {
  .help-body { flex-direction: column; }
  .help-divider { width: auto; height: 1px; }
  .help-card { width: 100%; margin: 0 12px; }
}
</style>
