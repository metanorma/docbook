<template>
  <div class="synopsis" :class="{ 'synopsis--labeled': block.attrs?.title }">
    <div v-if="block.attrs?.title" class="synopsis-header">
      <span class="synopsis-label">{{ block.attrs.title }}</span>
    </div>
    <div class="synopsis-body">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.synopsis {
  margin: 1.25rem 0;
  border-radius: 8px;
  border: 1px solid var(--ebook-border);
  background: var(--ebook-bg-secondary);
  overflow: hidden;
}

.synopsis--labeled {
  border-top: none;
}

.synopsis-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background: color-mix(in srgb, var(--ebook-border) 60%, transparent);
  border-bottom: 1px solid var(--ebook-border);
}

.synopsis-label {
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--ebook-text-muted);
  font-family: 'JetBrains Mono', ui-monospace, monospace;
}

.synopsis-body {
  padding: 1rem;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.82rem;
  line-height: 1.65;
  overflow-x: auto;
  color: var(--ebook-text);
}
</style>
