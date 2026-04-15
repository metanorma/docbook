<template>
  <div class="reference-entry mb-8 border-l-4 pl-4 py-3 rounded-r-lg">
    <!-- Reference meta (from refmeta - subtle metadata at top) -->
    <template v-for="(child, idx) in block.children" :key="'meta-' + idx">
      <span
        v-if="child.type === 'reference_meta'"
        class="reference-meta text-xs block mb-1"
      >
        {{ child.text }}
      </span>
    </template>

    <!-- Reference badge (from refnamediv.refclass - e.g., "pi") -->
    <template v-for="(child, idx) in block.children" :key="'badge-' + idx">
      <span
        v-if="child.type === 'reference_badge'"
        class="reference-badge inline-block text-[0.65rem] font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full mb-2"
      >
        {{ child.text }}
      </span>
    </template>

    <!-- Reference name (from refnamediv.refname - THE HEADWORD) -->
    <template v-for="(child, idx) in block.children" :key="'name-' + idx">
      <h2
        v-if="child.type === 'reference_name'"
        class="reference-name text-2xl font-bold font-mono mb-1"
      >
        {{ child.text }}
      </h2>
    </template>

    <!-- Reference definition (from refnamediv.refpurpose - THE DEFINITION) -->
    <template v-for="(child, idx) in block.children" :key="'def-' + idx">
      <p
        v-if="child.type === 'reference_definition'"
        class="reference-definition text-base italic mb-4"
      >
        {{ child.text }}
      </p>
    </template>

    <!-- Description section (from refsection) -->
    <template v-for="(child, idx) in block.children" :key="'section-' + idx">
      <div
        v-if="child.type === 'description_section'"
        class="description-section mt-4 pt-4 border-t"
      >
        <BlockRenderer :blocks="child.children || []" />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import type { ContentBlock } from '../stores/documentStore'
import BlockRenderer from './BlockRenderer.vue'

defineProps<{
  block: ContentBlock
}>()
</script>

<style scoped>
.reference-entry {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  border-color: var(--chrome-accent);
  background: color-mix(in srgb, var(--chrome-accent) 5%, var(--ebook-bg));
}

.reference-name {
  font-family: 'JetBrains Mono', 'Fira Code', ui-monospace, monospace;
  color: var(--chrome-accent);
}

.reference-meta {
  color: var(--ebook-text-muted);
}

.reference-badge {
  letter-spacing: 0.05em;
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.reference-definition {
  color: var(--ebook-text-muted);
}

.description-section {
  border-color: var(--ebook-border);
}
</style>
