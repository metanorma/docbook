<template>
  <div v-if="block.type === 'index_div'" class="mb-3">
    <h3 v-if="block.attrs?.title" class="text-lg font-bold heading-text mb-2">{{ block.attrs.title }}</h3>
    <MirrorRenderer :blocks="block.content || []" />
  </div>
  <div v-else class="mb-1 pl-4 ebook-text">
    <template v-for="(child, ci) in block.content" :key="ci">
      <TextRenderer v-if="child.type === 'text'" :node="child" />
    </template>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import TextRenderer from '@/components/TextRenderer.vue'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.heading-text { color: var(--ebook-text-heading); }
</style>
