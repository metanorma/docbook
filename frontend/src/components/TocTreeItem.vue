<template>
  <li>
    <!-- Item with children (collapsible) -->
    <template v-if="item.children && item.children.length > 0">
      <div class="flex items-start gap-1">
        <button
          @click="toggle"
          class="toc-toggle flex-shrink-0 w-6 h-6 flex items-center justify-center p-1 text-sm text-left rounded-md transition-colors self-center"
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
          class="toc-link flex items-center gap-2 py-1 px-1 text-sm rounded-md transition-colors flex-grow truncate"
          :class="linkClass"
        >
          <span v-if="typeLabel" class="toc-badge w-8 text-center text-xs px-1 py-0.5 rounded flex-shrink-0" :class="typeBadgeClass">{{ typeLabel }}</span>
          <span class="toc-number w-10 text-xs flex-shrink-0 font-mono text-right">{{ getNumber(item.id) }}</span>
          <span class="truncate">{{ item.title }}</span>
        </a>
      </div>
      <ul v-if="isOpen" class="toc-children pl-4 mt-0.5 space-y-0.5 border-l">
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
      class="toc-link flex items-center gap-2 py-1 px-1 pl-5 text-sm rounded-md transition-colors truncate"
      :class="linkClass"
    >
      <span v-if="typeLabel" class="toc-badge w-8 text-center text-xs px-1 py-0.5 rounded flex-shrink-0" :class="typeBadgeClass">{{ typeLabel }}</span>
      <span class="toc-number w-10 text-xs flex-shrink-0 font-mono text-right">{{ getNumber(item.id) }}</span>
      <span class="truncate">{{ item.title }}</span>
    </a>
  </li>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
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

// Auto-expand when active section is within this subtree
watch(() => uiStore.activeSectionId, (activeId) => {
  if (activeId && hasDescendant(props.item, activeId)) {
    isOpen.value = true
  }
})

function hasDescendant(item: TocItem, id: string): boolean {
  if (item.id === id) return true
  if (item.children) {
    return item.children.some(child => hasDescendant(child, id))
  }
  return false
}

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
    case 'dedication': return 'Ded'
    case 'acknowledgements': return 'Ack'
    case 'colophon': return 'Col'
    case 'reference': return 'Ref'
    case 'refentry': return 'p'
    case 'set': return 'Set'
    case 'article': return 'Art'
    case 'topic': return 'Top'
    default: return ''
  }
})

const typeBadgeClass = computed(() => {
  switch (props.item.type) {
    case 'part': return 'toc-badge-purple'
    case 'chapter': return 'toc-badge-blue'
    case 'appendix': return 'toc-badge-green'
    case 'section': return 'toc-badge-neutral'
    case 'glossary': return 'toc-badge-yellow'
    case 'bibliography': return 'toc-badge-red'
    case 'index': return 'toc-badge-indigo'
    case 'preface': return 'toc-badge-orange'
    case 'dedication': return 'toc-badge-muted'
    case 'acknowledgements': return 'toc-badge-muted'
    case 'colophon': return 'toc-badge-muted'
    case 'reference': return 'toc-badge-cyan'
    case 'refentry': return 'toc-badge-neutral toc-badge-mono'
    default: return 'toc-badge-neutral'
  }
})

const buttonClass = computed(() => {
  if (props.item.type === 'part') {
    return 'toc-text-bold'
  }
  return ''
})

const isFrontmatter = computed(() => {
  return ['dedication', 'acknowledgements', 'preface', 'colophon'].includes(props.item.type)
})

const linkClass = computed(() => {
  const isActive = uiStore.activeSectionId === props.item.id
  if (isActive) {
    return 'toc-active'
  }
  if (props.item.type === 'part') {
    return 'toc-text-bold'
  }
  if (isFrontmatter.value) {
    return 'toc-text-frontmatter'
  }
  return 'toc-text-muted'
})

function toggle() {
  isOpen.value = !isOpen.value
}

function getNumber(id: string): string {
  return documentStore.getNumbering(id)
}
</script>

<style scoped>
.toc-toggle {
  color: var(--chrome-text);
}
.toc-toggle:hover {
  background: var(--chrome-bg-hover);
}

.toc-link {
  color: var(--chrome-text-dim);
  text-decoration: none;
}
.toc-link:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.toc-number {
  color: var(--chrome-text-dim);
}

.toc-children {
  border-color: var(--chrome-border);
}

.toc-text-bold {
  font-weight: 600;
  color: var(--chrome-text);
}
.toc-text-muted {
  color: var(--chrome-text-dim);
}

.toc-text-frontmatter {
  color: var(--chrome-text-dim);
  font-style: italic;
}

.toc-active {
  background: color-mix(in srgb, var(--chrome-accent) 15%, transparent);
  color: var(--chrome-accent);
  font-weight: 500;
}
.toc-active:hover {
  background: color-mix(in srgb, var(--chrome-accent) 25%, transparent);
}

/* Type badges */
.toc-badge {
  font-weight: 500;
}
.toc-badge-purple {
  background: color-mix(in srgb, #8b5cf6 20%, var(--chrome-bg-hover));
  color: #8b5cf6;
}
.toc-badge-blue {
  background: color-mix(in srgb, #3b82f6 20%, var(--chrome-bg-hover));
  color: #3b82f6;
}
.toc-badge-green {
  background: color-mix(in srgb, #22c55e 20%, var(--chrome-bg-hover));
  color: #22c55e;
}
.toc-badge-yellow {
  background: color-mix(in srgb, #eab308 20%, var(--chrome-bg-hover));
  color: #eab308;
}
.toc-badge-red {
  background: color-mix(in srgb, #ef4444 20%, var(--chrome-bg-hover));
  color: #ef4444;
}
.toc-badge-indigo {
  background: color-mix(in srgb, #6366f1 20%, var(--chrome-bg-hover));
  color: #6366f1;
}
.toc-badge-orange {
  background: color-mix(in srgb, #f97316 20%, var(--chrome-bg-hover));
  color: #f97316;
}
.toc-badge-cyan {
  background: color-mix(in srgb, #06b6d4 20%, var(--chrome-bg-hover));
  color: #06b6d4;
}
.toc-badge-neutral {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.toc-badge-muted {
  background: transparent;
  color: var(--chrome-text-dim);
  opacity: 0.7;
}
.toc-badge-mono {
  font-family: ui-monospace, monospace;
  font-size: 0.75rem;
}
</style>
