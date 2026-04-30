<template>
  <div class="annotation-inline">
    <span
      class="annotation-marker"
      @mouseenter="showAnnotation($event)"
      @mouseleave="scheduleHideAnnotation"
      @click="toggleAnnotation($event)"
    >
      <svg class="annotation-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    </span>
    <AnnotationPopup
      :visible="active"
      :targetRect="targetRect"
      @mouseenter="cancelHideAnnotation"
      @mouseleave="scheduleHideAnnotation"
    >
      <MirrorRenderer :blocks="block.content || []" />
    </AnnotationPopup>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'
import AnnotationPopup from '@/components/AnnotationPopup.vue'

defineProps<{ block: MirrorBlockNode }>()

const active = ref(false)
const targetRect = ref<DOMRect | null>(null)
let hideTimer: ReturnType<typeof setTimeout> | null = null

function showAnnotation(event: MouseEvent) {
  const target = event.currentTarget as HTMLElement
  targetRect.value = target.getBoundingClientRect()
  active.value = true
  cancelHideAnnotation()
}

function scheduleHideAnnotation() {
  hideTimer = setTimeout(() => {
    active.value = false
  }, 200)
}

function cancelHideAnnotation() {
  if (hideTimer) {
    clearTimeout(hideTimer)
    hideTimer = null
  }
}

function toggleAnnotation(event: MouseEvent) {
  if (active.value) {
    active.value = false
  } else {
    showAnnotation(event)
  }
}
</script>

<style scoped>
.annotation-inline { display: inline; }
.annotation-marker {
  display: inline-flex; align-items: center; justify-content: center;
  width: 20px; height: 20px; border-radius: 50%;
  background: color-mix(in srgb, var(--ebook-link-color) 12%, var(--ebook-bg));
  color: var(--ebook-link-color); cursor: pointer; vertical-align: super;
  margin: 0 2px; transition: background 0.15s ease;
}
.annotation-marker:hover { background: color-mix(in srgb, var(--ebook-link-color) 25%, var(--ebook-bg)); }
.annotation-icon { width: 12px; height: 12px; }
</style>
