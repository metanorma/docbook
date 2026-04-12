<template>
  <li>
    <!-- Item with children (collapsible) -->
    <template v-if="item.children && item.children.length > 0">
      <div class="flex items-start gap-1">
        <button
          @click="toggle"
          class="flex-shrink-0 w-6 h-6 flex items-center justify-center p-1 text-sm text-left rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors self-center"
          :class="buttonClass"
        >
          <svg
            class="w-3.5 h-3.5 transition-transform"
            :class="{ 'rotate-90': isOpen }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
          </svg>
        </button>
        <a
          :href="'#' + item.id"
          class="flex items-center gap-2 py-1 px-1 text-sm rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-gray-100 transition-colors flex-grow truncate"
          :class="linkClass"
        >
          <span v-if="typeLabel" class="w-8 text-center text-xs px-1 py-0.5 rounded flex-shrink-0" :class="typeBadgeClass">{{ typeLabel }}</span>
          <span class="w-10 text-xs text-gray-500 dark:text-gray-400 flex-shrink-0 font-mono text-right">{{ getNumber(item.id) }}</span>
          <span class="truncate">{{ item.title }}</span>
        </a>
      </div>
      <ul v-if="isOpen" class="pl-4 mt-0.5 space-y-0.5 border-l border-gray-200 dark:border-gray-700">
        <TocTreeItem
          v-for="child in item.children"
          :key="child.id"
          :item="child"
          :depth="depth + 1"
        />
      </ul>
    </template>

    <!-- Leaf item (no children) -->
    <a
      v-else
      :href="'#' + item.id"
      class="flex items-center gap-2 py-1 px-1 pl-5 text-sm rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-gray-100 transition-colors truncate"
      :class="linkClass"
    >
      <span v-if="typeLabel" class="w-8 text-center text-xs px-1 py-0.5 rounded flex-shrink-0" :class="typeBadgeClass">{{ typeLabel }}</span>
      <span class="w-10 text-xs text-gray-500 dark:text-gray-400 flex-shrink-0 font-mono text-right">{{ getNumber(item.id) }}</span>
      <span class="truncate">{{ item.title }}</span>
    </a>
  </li>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'

interface Props {
  item: TocItem
  depth: number
}

const props = defineProps<Props>()
const documentStore = useDocumentStore()
const uiStore = useUiStore()
const isOpen = ref(props.depth <= 1)

const typeLabel = computed(() => {
  switch (props.item.type) {
    case 'part': return 'Pt'
    case 'chapter': return 'Ch'
    case 'appendix': return 'App'
    case 'section': return ''
    case 'glossary': return 'Gl'
    case 'bibliography': return 'Bib'
    case 'index': return 'Idx'
    case 'preface': return 'Pref'
    case 'reference': return 'Ref'
    default: return ''
  }
})

const typeBadgeClass = computed(() => {
  switch (props.item.type) {
    case 'part':
      return 'bg-purple-200 dark:bg-purple-800 text-purple-800 dark:text-purple-200 font-medium'
    case 'chapter':
      return 'bg-blue-200 dark:bg-blue-800 text-blue-800 dark:text-blue-200 font-medium'
    case 'appendix':
      return 'bg-green-200 dark:bg-green-800 text-green-800 dark:text-green-200 font-medium'
    case 'section':
      return 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400'
    case 'glossary':
      return 'bg-yellow-200 dark:bg-yellow-800 text-yellow-800 dark:text-yellow-200 font-medium'
    case 'bibliography':
      return 'bg-red-200 dark:bg-red-800 text-red-800 dark:text-red-200 font-medium'
    case 'index':
      return 'bg-indigo-200 dark:bg-indigo-800 text-indigo-800 dark:text-indigo-200 font-medium'
    case 'preface':
      return 'bg-orange-200 dark:bg-orange-800 text-orange-800 dark:text-orange-200 font-medium'
    case 'reference':
      return 'bg-cyan-200 dark:bg-cyan-800 text-cyan-800 dark:text-cyan-200 font-medium'
    default:
      return 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400'
  }
})

const buttonClass = computed(() => {
  if (props.item.type === 'part') {
    return 'font-semibold text-gray-800 dark:text-gray-100'
  }
  return 'text-gray-700 dark:text-gray-300'
})

const linkClass = computed(() => {
  const isActive = uiStore.activeSectionId === props.item.id
  if (isActive) {
    return 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 font-medium'
  }
  if (props.item.type === 'part') {
    return 'font-semibold text-gray-800 dark:text-gray-100'
  }
  return 'text-gray-600 dark:text-gray-400'
})

function toggle() {
  isOpen.value = !isOpen.value
}

function getNumber(id: string): string {
  return documentStore.getNumbering(id)
}
</script>
