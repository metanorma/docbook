<template>
  <div :id="block.attrs?.xml_id" class="equation-block my-6 text-center">
    <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-2">
      <span v-if="getNumbering(block.attrs?.xml_id)">Equation {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
    </div>
    <div class="equation-content">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()

const documentStore = useDocumentStore()

function getNumbering(id: string | undefined): string {
  if (!id) return ''
  return documentStore.getNumbering(id)
}
</script>

<style scoped>
.muted-text { color: var(--ebook-text-muted); }
.equation-block { padding: 1rem; background: var(--ebook-bg-secondary); border-radius: 8px; border: 1px solid var(--ebook-border); }
.equation-content { font-size: 1.1em; }
</style>
