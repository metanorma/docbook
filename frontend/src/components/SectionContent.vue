<template>
  <section :id="section.id" class="mb-8 scroll-mt-20">
    <h3 class="text-lg font-semibold mb-3 text-gray-800 dark:text-gray-200">
      <span v-if="numbering" class="text-gray-500 dark:text-gray-400 mr-2">{{ numbering }}</span>
      {{ section.title }}
    </h3>
    <BlockRenderer v-if="sectionContent" :blocks="sectionContent.blocks" />
    <!-- Render children -->
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
import BlockRenderer from '@/components/BlockRenderer.vue'

interface Props {
  section: TocItem
}

const props = defineProps<Props>()
const documentStore = useDocumentStore()

const numbering = computed(() => documentStore.getNumbering(props.section.id))
const sectionContent = computed(() => documentStore.getSectionContent(props.section.id))
</script>
