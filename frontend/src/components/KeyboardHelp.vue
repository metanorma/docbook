<template>
  <Teleport to="body">
    <Transition name="help-overlay">
      <div v-if="visible" class="help-backdrop" role="dialog" aria-label="Keyboard shortcuts" @click.self="close">
        <div class="help-card">
          <div class="help-header">
            <h2 class="help-title">Keyboard Shortcuts</h2>
            <button class="help-close" @click="close">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <div class="help-grid">
            <div class="help-group">
              <h3 class="help-group-title">Navigation</h3>
              <div class="help-row" v-for="s in navigation" :key="s.key">
                <kbd class="help-key">{{ s.key }}</kbd>
                <span class="help-desc">{{ s.desc }}</span>
              </div>
            </div>

            <div class="help-group">
              <h3 class="help-group-title">Display</h3>
              <div class="help-row" v-for="s in display" :key="s.key">
                <kbd class="help-key">{{ s.key }}</kbd>
                <span class="help-desc">{{ s.desc }}</span>
              </div>
            </div>
          </div>

          <div class="help-footer">Press <kbd class="help-key help-key--sm">?</kbd> or <kbd class="help-key help-key--sm">Esc</kbd> to close</div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
defineProps<{
  visible: boolean
}>()

const emit = defineEmits<{
  close: []
}>()

function close() {
  emit('close')
}

const navigation = [
  { key: 'j', desc: 'Next section' },
  { key: 'k', desc: 'Previous section' },
  { key: '/', desc: 'Open search' },
  { key: 't', desc: 'Toggle sidebar' },
]

const display = [
  { key: 's', desc: 'Toggle settings' },
  { key: 'f', desc: 'Focus mode' },
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
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.help-card {
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  border-radius: 16px;
  width: 420px;
  max-width: 90vw;
  overflow: hidden;
  box-shadow: 0 16px 64px rgba(0, 0, 0, 0.2);
}

.help-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--chrome-border);
}

.help-title {
  font-size: 0.85rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--chrome-text);
}

.help-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  color: var(--chrome-text-dim);
  transition: background 0.15s ease;
}
.help-close:hover {
  background: var(--chrome-bg-hover);
}

.help-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0;
}

.help-group {
  padding: 16px 20px;
}

.help-group:first-child {
  border-right: 1px solid var(--chrome-border);
}

.help-group-title {
  font-size: 0.65rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--chrome-accent);
  margin-bottom: 10px;
}

.help-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 5px 0;
}

.help-key {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 28px;
  height: 24px;
  padding: 0 6px;
  font-family: system-ui, -apple-system, sans-serif;
  font-size: 0.7rem;
  font-weight: 600;
  border-radius: 5px;
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
  border: 1px solid var(--chrome-border);
  box-shadow: 0 1px 0 var(--chrome-border);
}

.help-key--sm {
  min-width: 24px;
  height: 20px;
  font-size: 0.6rem;
  padding: 0 4px;
}

.help-desc {
  font-size: 0.8rem;
  color: var(--chrome-text-dim);
}

.help-footer {
  padding: 12px 20px;
  border-top: 1px solid var(--chrome-border);
  font-size: 0.75rem;
  color: var(--chrome-text-dim);
  text-align: center;
}

.help-footer .help-key {
  min-width: auto;
  height: 18px;
  padding: 0 4px;
  font-size: 0.6rem;
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
</style>
