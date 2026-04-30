<template>
  <MirrorRenderer v-if="block.type === 'gloss_entry'" :blocks="block.content || []" />
  <dt v-else-if="block.type === 'gloss_term'" class="font-bold ebook-text">
    <MirrorRenderer :blocks="block.content || []" />
  </dt>
  <dd v-else-if="block.type === 'gloss_def'" class="ml-4 mb-2 ebook-text">
    <MirrorRenderer :blocks="block.content || []" />
  </dd>
  <dd v-else-if="block.type === 'gloss_see'" class="ml-4 mb-1 text-sm muted-text italic">
    See: <a v-if="block.attrs?.otherterm" :href="`#${block.attrs.otherterm}`" class="ebook-link-color">{{ extractText(block) }}</a>
    <template v-else>{{ extractText(block) }}</template>
  </dd>
  <dd v-else class="ml-4 mb-1 text-sm muted-text italic">
    See also: <a v-if="block.attrs?.otherterm" :href="`#${block.attrs.otherterm}`" class="ebook-link-color">{{ extractText(block) }}</a>
    <template v-else>{{ extractText(block) }}</template>
  </dd>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'
import { extractText } from '@/utils/nodeExtract'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.muted-text { color: var(--ebook-text-muted); }
.ebook-link-color { color: var(--ebook-link-color); }
.ebook-link-color:hover { text-decoration: underline; }
</style>
