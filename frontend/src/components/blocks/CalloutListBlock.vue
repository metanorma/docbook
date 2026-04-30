<template>
  <div v-if="block.type === 'calloutlist'" :id="block.attrs?.xml_id" class="calloutlist">
    <div v-if="block.attrs?.title" class="calloutlist-title">{{ block.attrs.title }}</div>
    <ol class="calloutlist-entries">
      <MirrorRenderer :blocks="block.content || []" />
    </ol>
  </div>
  <li v-else :id="block.attrs?.xml_id" class="calloutlist-item">
    <span class="calloutlist-badge"></span>
    <div class="calloutlist-text">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </li>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.calloutlist {
  margin: 1rem 0;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  background: color-mix(in srgb, var(--ebook-bg-secondary) 60%, transparent);
  border: 1px solid var(--ebook-border);
}

.calloutlist-title {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--ebook-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 0.5rem;
}

.calloutlist-entries {
  list-style: none;
  padding: 0;
  margin: 0;
  counter-reset: callout-counter;
}

.calloutlist-item {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.4rem 0;
  font-size: 0.92em;
  color: var(--ebook-text);
  line-height: 1.6;
  counter-increment: callout-counter;
}

.calloutlist-item + .calloutlist-item {
  border-top: 1px solid color-mix(in srgb, var(--ebook-border) 50%, transparent);
}

.calloutlist-badge {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 1.5em;
  height: 1.5em;
  font-size: 0.7em;
  font-weight: 700;
  font-family: system-ui, -apple-system, sans-serif;
  color: #fff;
  background: var(--ebook-link-color);
  border-radius: 50%;
  padding: 0 0.2em;
  margin-top: 3px;
}

.calloutlist-badge::before {
  content: counter(callout-counter);
}

.calloutlist-text {
  flex: 1;
  min-width: 0;
}
</style>
