<template>
  <Teleport to="body">
    <div class="toast-container">
      <TransitionGroup name="toast">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="toast-item"
          :class="`toast--${toast.type}`"
          @click="dismissToast(toast.id)"
        >
          <span class="toast-icon">
            <svg v-if="toast.type === 'success'" class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
            </svg>
            <svg v-else class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
          </span>
          <span class="toast-message">{{ toast.message }}</span>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { useToast } from '@/composables/useToast'

const { toasts, dismissToast } = useToast()
</script>

<style scoped>
.toast-container {
  position: fixed;
  bottom: 28px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 60;
  display: flex;
  flex-direction: column-reverse;
  gap: 8px;
  align-items: center;
  pointer-events: none;
}

.toast-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  border-radius: 10px;
  background: var(--chrome-bg);
  border: 1px solid var(--chrome-border);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.12), 0 1px 4px rgba(0, 0, 0, 0.06);
  backdrop-filter: blur(12px);
  pointer-events: auto;
  cursor: pointer;
  max-width: 360px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.toast-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.toast--success .toast-icon {
  color: var(--chrome-accent);
}

.toast--info .toast-icon {
  color: var(--chrome-text-dim);
}

.toast-message {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--chrome-text);
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Animations */
.toast-enter-active {
  transition: opacity 0.25s ease, transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.toast-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateY(12px) scale(0.96);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.96);
}
.toast-move {
  transition: transform 0.25s ease;
}

@media (max-width: 640px) {
  .toast-container {
    left: 16px;
    right: 16px;
    transform: none;
  }
  .toast-item {
    max-width: 100%;
    white-space: normal;
  }
}
</style>
