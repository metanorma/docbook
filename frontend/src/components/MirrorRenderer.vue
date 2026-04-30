<template>
  <div class="content-blocks">
    <template v-for="(block, index) in blocks" :key="index">
      <template v-if="!isTopLevel || isProgressiveRevealed(index)">
        <MirrorRenderer v-if="block.type === 'doc'" :blocks="block.content || []" />
        <TextRenderer v-else-if="block.type === 'text'" :node="block" />
        <SectionBlock v-else-if="isSectionType(block.type)" :block="block" />
        <br v-else-if="block.type === 'soft_break'" />
        <component v-else :is="getBlockComponent(block.type)" :block="block" />
      </template>
      <div v-else class="progressive-placeholder"></div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { inject, type Ref } from 'vue'
import type { MirrorBlockNode, MirrorTextNode } from '@/stores/documentStore'
import SectionBlock from './blocks/SectionBlock.vue'
import TextRenderer from './TextRenderer.vue'
import { getBlockComponent } from './blocks'
import { isSectionType } from '@/utils/typeMetadata'

const props = defineProps<{
  blocks: (MirrorBlockNode | MirrorTextNode)[]
  top?: boolean
}>()

const isTopLevel = !!props.top

// Progressive rendering: only top-level MirrorRenderer gates blocks
const progressiveRevealedCount = inject<Ref<number>>('progressiveRevealedCount', { value: Infinity } as Ref<number>)

function isProgressiveRevealed(index: number): boolean {
  return index < progressiveRevealedCount.value
}
</script>

<style scoped>
.progressive-placeholder {
  min-height: 80px;
}
</style>
