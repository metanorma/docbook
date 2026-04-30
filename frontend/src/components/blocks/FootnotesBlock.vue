<template>
  <div class="footnotes">
    <div class="footnotes-rule"></div>
    <ol class="footnotes-list">
      <li v-for="fn in block.content" :key="fn.attrs?.id" :id="fn.attrs?.id" class="footnote-item">
        <MirrorRenderer :blocks="fn.content || []" />
        <a :href="`#${fn.attrs?.ref_id}`" class="footnote-backref">&#8617;</a>
      </li>
    </ol>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.footnotes {
  margin-top: 3rem;
  padding-top: 1.5rem;
}

.footnotes-rule {
  width: 80px;
  height: 1px;
  background: linear-gradient(to right, var(--ebook-border), transparent);
  margin-bottom: 1rem;
}

.footnotes-list {
  list-style: decimal;
  padding-left: 1.5rem;
  margin: 0;
}

.footnote-item {
  margin-bottom: 0.5rem;
  font-size: 0.82rem;
  line-height: 1.55;
  color: var(--ebook-text-muted);
}

.footnote-backref {
  color: var(--ebook-link-color);
  text-decoration: none;
  font-size: 0.75em;
  margin-left: 4px;
  transition: color 0.15s ease;
}

.footnote-backref:hover {
  text-decoration: underline;
}
</style>
