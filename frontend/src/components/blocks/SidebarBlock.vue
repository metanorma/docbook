<template>
  <aside :id="block.attrs?.xml_id" class="sidebar-block my-4">
    <div v-if="block.attrs?.title" class="sidebar-title">{{ block.attrs.title }}</div>
    <MirrorRenderer :blocks="block.content || []" />
  </aside>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.sidebar-block { padding: 1rem 1.25rem; border-left: 3px solid var(--ebook-accent); background: color-mix(in srgb, var(--ebook-accent) 5%, var(--ebook-bg)); border-radius: 0 8px 8px 0; }
.sidebar-title { font-weight: 600; font-size: 0.9em; text-transform: uppercase; letter-spacing: 0.04em; color: var(--ebook-accent); margin-bottom: 0.5rem; }
</style>
