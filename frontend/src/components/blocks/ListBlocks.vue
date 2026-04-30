<template>
  <ol v-if="block.type === 'ordered_list'" class="list-decimal ml-6 mb-3 space-y-1">
    <li v-for="(item, li) in block.content" :key="li" class="ebook-text">
      <template v-if="item.type === 'list_item'">
        <MirrorRenderer :blocks="item.content || []" />
      </template>
    </li>
  </ol>
  <ul v-else-if="block.type === 'bullet_list'" class="list-disc ml-6 mb-3 space-y-1">
    <li v-for="(item, li) in block.content" :key="li" class="ebook-text">
      <template v-if="item.type === 'list_item'">
        <MirrorRenderer :blocks="item.content || []" />
      </template>
    </li>
  </ul>
  <dl v-else class="mb-4 ml-4">
    <template v-for="(item, di) in block.content" :key="di">
      <template v-if="item.type === 'definition_term'">
        <dt class="font-semibold ebook-text mt-2">
          <MirrorRenderer :blocks="item.content || []" />
        </dt>
      </template>
      <template v-if="item.type === 'definition_description'">
        <dd class="ml-4 muted-text mb-2">
          <MirrorRenderer :blocks="item.content || []" />
        </dd>
      </template>
    </template>
  </dl>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.muted-text { color: var(--ebook-text-muted); }
</style>
