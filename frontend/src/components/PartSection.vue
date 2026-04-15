<template>
  <section :id="section.id" class="mb-12 scroll-mt-20">
    <h1 class="part-heading text-2xl font-bold mb-6 pb-2 border-b-2">
      {{ section.title }}
    </h1>
    <BlockRenderer v-if="sectionContent" :blocks="sectionContent.blocks" />
    <!-- Render children -->
    <template v-if="section.children && section.children.length > 0">
      <div v-for="child in section.children" :key="child.id">
        <component :is="getChildComponent(child.type)" :section="child" />
      </div>
    </template>
  </section>
</template>

<script setup lang="ts">
import { computed, markRaw } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import SectionContent from '@/components/SectionContent.vue'
import ChapterSection from '@/components/ChapterSection.vue'
import AppendixSection from '@/components/AppendixSection.vue'
import BlockRenderer from '@/components/BlockRenderer.vue'

interface Props {
  section: TocItem
}

const props = defineProps<Props>()
const documentStore = useDocumentStore()

const sectionContent = computed(() => documentStore.getSectionContent(props.section.id))

function getChildComponent(type: string) {
  switch (type) {
    case 'chapter':
    case 'reference':
      return markRaw(ChapterSection)
    case 'appendix':
      return markRaw(AppendixSection)
    default:
      return markRaw(SectionContent)
  }
}
</script>

<style scoped>
.part-heading {
  border-color: var(--ebook-border);
}
</style>
