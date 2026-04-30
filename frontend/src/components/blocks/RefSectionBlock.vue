<template>
  <div :id="block.attrs?.xml_id" class="refsection">
    <div v-if="block.attrs?.title" class="refsection-header">
      <span class="refsection-badge">ref</span>
      <h3 class="refsection-title">{{ block.attrs.title }}</h3>
    </div>
    <div class="refsection-body">
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
.refsection {
  margin: 1.25rem 0;
  padding: 1rem;
  border-radius: 8px;
  border: 1px solid var(--ebook-border);
  background: var(--ebook-bg-secondary);
}

.refsection-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 0.75rem;
  padding-bottom: 0.6rem;
  border-bottom: 1px solid var(--ebook-border);
}

.refsection-badge {
  font-size: 0.6rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--ebook-accent) 12%, transparent);
  color: var(--ebook-accent);
  font-family: 'JetBrains Mono', ui-monospace, monospace;
}

.refsection-title {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--ebook-text-heading);
  margin: 0;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
}

.refsection-body {
  color: var(--ebook-text);
}
</style>
