<template>
  <div :id="block.attrs?.xml_id" class="biblio-entry">
    <span class="biblio-marker" aria-hidden="true"></span>
    <div class="biblio-content">
      <template v-for="(child, ci) in block.content" :key="ci">
        <TextRenderer v-if="child.type === 'text'" :node="child" />
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import TextRenderer from '@/components/TextRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.biblio-entry {
  position: relative;
  padding: 0.65rem 0 0.65rem 2rem;
  margin-bottom: 0.25rem;
  border-radius: 0 6px 6px 0;
  transition: background 0.15s ease;
}

.biblio-marker {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  border-radius: 3px;
  background: linear-gradient(
    to bottom,
    var(--ebook-accent),
    color-mix(in srgb, var(--ebook-accent) 40%, transparent)
  );
  opacity: 0.35;
  transition: opacity 0.15s ease;
}

.biblio-entry:hover .biblio-marker {
  opacity: 0.7;
}

.biblio-entry:hover {
  background: color-mix(in srgb, var(--ebook-bg-secondary) 60%, transparent);
}

.biblio-content {
  font-size: 0.88rem;
  line-height: 1.65;
  color: var(--ebook-text);
  letter-spacing: -0.003em;
}

.biblio-content :deep(.font-bold) {
  color: var(--ebook-text-heading);
  font-weight: 600;
}

.biblio-content :deep(.citation) {
  font-style: italic;
  color: var(--ebook-text);
}

.biblio-content :deep(.inline-code) {
  font-size: 0.82rem;
}
</style>
