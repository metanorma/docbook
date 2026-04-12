<template>
  <section :id="section.id" class="mb-12 scroll-mt-20">
    <h2 class="flex items-baseline gap-3 text-xl font-bold mb-5 pb-2 border-b border-gray-200 dark:border-gray-700">
      <span class="text-gray-500 dark:text-gray-400 text-lg font-normal">{{ numbering }}</span>
      <span>{{ section.title }}</span>
    </h2>
    <BlockRenderer v-if="sectionContent" :blocks="sectionContent.blocks" />
    <!-- Render children if any -->
    <template v-if="section.children && section.children.length > 0">
      <div v-for="child in section.children" :key="child.id" class="ml-4">
        <SectionContent :section="child" />
      </div>
    </template>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import SectionContent from '@/components/SectionContent.vue'
import BlockRenderer from '@/components/BlockRenderer.vue'

interface Props {
  section: TocItem
}

const props = defineProps<Props>()
const documentStore = useDocumentStore()

const numbering = computed(() => documentStore.getNumbering(props.section.id))
const sectionContent = computed(() => documentStore.getSectionContent(props.section.id))
</script>
