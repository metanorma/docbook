<template>
  <Teleport to="body">
    <Transition name="lightbox">
      <div v-if="visible" class="lightbox-overlay" @click="close" @keydown.escape="close">
        <div class="lightbox-content" @click.stop>
          <img :src="src" :alt="alt" class="lightbox-image" />
          <div v-if="title" class="lightbox-caption">{{ title }}</div>
        </div>
        <button class="lightbox-close" @click="close" title="Close (Esc)">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'

defineProps<{
  visible: boolean
  src: string
  alt?: string
  title?: string
}>()

const emit = defineEmits<{
  close: []
}>()

function close() {
  emit('close')
}

function handleKey(e: KeyboardEvent) {
  if (e.key === 'Escape') {
    close()
  }
}

onMounted(() => {
  document.addEventListener('keydown', handleKey)
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleKey)
})
</script>

<style scoped>
.lightbox-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(0, 0, 0, 0.92);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: zoom-out;
}

.lightbox-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  max-width: 95vw;
  max-height: 90vh;
}

.lightbox-image {
  max-width: 95vw;
  max-height: 85vh;
  object-fit: contain;
  border-radius: 4px;
}

.lightbox-caption {
  margin-top: 12px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.875rem;
  text-align: center;
}

.lightbox-close {
  position: absolute;
  top: 16px;
  right: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.8);
  border: none;
  cursor: pointer;
  transition: background 0.15s ease;
}

.lightbox-close:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.lightbox-enter-active,
.lightbox-leave-active {
  transition: opacity 0.2s ease;
}

.lightbox-enter-from,
.lightbox-leave-to {
  opacity: 0;
}

.lightbox-enter-active .lightbox-image,
.lightbox-leave-active .lightbox-image {
  transition: transform 0.2s ease;
}

.lightbox-enter-from .lightbox-image,
.lightbox-leave-to .lightbox-image {
  transform: scale(0.95);
}
</style>
