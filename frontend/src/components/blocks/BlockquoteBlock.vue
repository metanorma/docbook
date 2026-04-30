<template>
  <blockquote class="blockquote">
    <MirrorRenderer :blocks="block.content || []" />
  </blockquote>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.blockquote {
  position: relative;
  border-left: 3px solid var(--ebook-accent);
  padding: 0.75rem 1rem 0.75rem 1.5rem;
  margin: 1.5rem 0;
  font-style: italic;
  color: var(--ebook-text-muted);
  background: var(--ebook-bg-secondary);
  border-radius: 0 8px 8px 0;
}

.blockquote::before {
  content: '\201C';
  position: absolute;
  left: 0.15em;
  top: -0.15em;
  font-size: 2.5em;
  color: var(--ebook-accent);
  opacity: 0.12;
  font-family: Georgia, 'Times New Roman', serif;
  line-height: 1;
  pointer-events: none;
}
</style>
