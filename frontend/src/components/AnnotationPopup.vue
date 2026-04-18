<template>
  <Teleport to="body">
    <div
      v-if="visible"
      ref="popupRef"
      class="annotation-popup"
      :style="popupStyle"
      @mouseenter="$emit('mouseenter')"
      @mouseleave="$emit('mouseleave')"
    >
      <div class="annotation-popup-content">
        <slot />
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, nextTick, watch } from 'vue'

const props = defineProps<{
  visible: boolean
  targetRect: DOMRect | null
}>()

defineEmits<{
  mouseenter: []
  mouseleave: []
}>()

const popupRef = ref<HTMLElement | null>(null)

const popupStyle = computed(() => {
  if (!props.targetRect) return { display: 'none' }

  const rect = props.targetRect
  const viewportWidth = window.innerWidth
  const viewportHeight = window.innerHeight

  let left = rect.left + window.scrollX
  let top = rect.bottom + window.scrollY + 8

  // Keep popup within viewport horizontally
  const popupWidth = 360
  if (left + popupWidth > viewportWidth) {
    left = viewportWidth - popupWidth - 16
  }
  if (left < 16) left = 16

  // If would overflow bottom, show above
  const estimatedHeight = 200
  if (rect.bottom + estimatedHeight > viewportHeight) {
    top = rect.top + window.scrollY - estimatedHeight - 8
  }

  return {
    position: 'absolute',
    left: `${left}px`,
    top: `${top}px`,
    maxWidth: '360px',
    zIndex: 9999,
  }
})
</script>

<style scoped>
.annotation-popup {
  background: var(--ebook-bg);
  border: 1px solid var(--ebook-border);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  padding: 12px 16px;
  font-size: 0.9em;
  line-height: 1.5;
  color: var(--ebook-text);
}

.annotation-popup-content {
  max-height: 300px;
  overflow-y: auto;
}
</style>
