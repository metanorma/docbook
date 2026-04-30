<template>
  <p :id="block.attrs?.xml_id"
     :class="[
       block.attrs?.class === 'refmeta-synopsis'
         ? 'mb-2 px-3 py-2 bg-ebook-bg-secondary rounded border border-ebook-border font-mono text-sm'
         : block.attrs?.class === 'refpurpose'
         ? 'mb-1 ebook-text leading-relaxed italic muted-text'
         : block.attrs?.class === 'refclass'
         ? 'mb-3 text-xs font-mono px-2 py-0.5 rounded inline-block refclass-badge'
         : 'mb-3 ebook-text leading-relaxed'
     ]">
    <template v-for="(child, ci) in block.content" :key="ci">
      <TextRenderer v-if="child.type === 'text'" :node="child" />
      <sup v-else-if="child.type === 'footnote_marker'" class="footnote-marker">
        <a :href="`#${child.attrs?.id}`" :id="child.attrs?.ref_id">{{ child.attrs?.number }}</a>
      </sup>
    </template>
  </p>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import TextRenderer from '@/components/TextRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.muted-text { color: var(--ebook-text-muted); }
.bg-ebook-bg-secondary { background: var(--ebook-bg-secondary); }
.border-ebook-border { border-color: var(--ebook-border); }
.refclass-badge { background: var(--chrome-bg-hover); color: var(--chrome-text-dim); }
.footnote-marker { font-size: 0.75em; vertical-align: super; line-height: 0; }
.footnote-marker a { color: var(--ebook-link-color); text-decoration: none; cursor: pointer; }
.footnote-marker a:hover { text-decoration: underline; }
</style>
