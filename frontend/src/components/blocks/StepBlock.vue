<template>
  <li v-if="block.type === 'step'" :id="block.attrs?.xml_id" class="step-item">
    <div class="step-content">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </li>
  <li v-else class="substeps-item">
    <ol class="substep-list">
      <MirrorRenderer :blocks="block.content || []" />
    </ol>
  </li>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.step-item {
  position: relative;
  margin-bottom: 1rem;
  padding-left: 2rem;
  min-height: 28px;
}

.step-item::before {
  content: counter(step-counter);
  counter-increment: step-counter;
  position: absolute;
  left: 0;
  top: 2px;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: color-mix(in srgb, var(--ebook-accent) 12%, var(--ebook-bg));
  color: var(--ebook-accent);
  font-size: 0.65rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
}

.step-content {
  line-height: 1.6;
  color: var(--ebook-text);
}

.substeps-item {
  list-style: none;
}

.substep-list {
  list-style: lower-alpha;
  padding-left: 1.5rem;
  margin-top: 0.5rem;
}
</style>
