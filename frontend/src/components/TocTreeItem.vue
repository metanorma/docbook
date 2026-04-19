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
          ref="linkEl"
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
      ref="linkEl"
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
import { getTypeLabel, getTypeBadgeClass } from '@/utils/typeMetadata'

interface Props {
  item: TocItem
  depth: number
}

const props = defineProps<Props>()
const documentStore = useDocumentStore()
const uiStore = useUiStore()
const isOpen = ref(props.depth <= 1)
const linkEl = ref<HTMLElement | null>(null)

// Auto-expand when active section is within this subtree
watch(() => uiStore.activeSectionId, (activeId) => {
  if (activeId && hasDescendant(props.item, activeId)) {
    isOpen.value = true
  }

  // Auto-scroll active item into view in the TOC sidebar
  if (activeId && activeId === props.item.id && linkEl.value && uiStore.tocFollowFocus) {
    linkEl.value.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }
})

function hasDescendant(item: TocItem, id: string): boolean {
  if (item.id === id) return true
  if (item.children) {
    return item.children.some(child => hasDescendant(child, id))
  }
  return false
}

const typeLabel = computed(() => getTypeLabel(props.item.type))
const typeBadgeClass = computed(() => getTypeBadgeClass(props.item.type))

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
.badge-purple {
  background: color-mix(in srgb, #8b5cf6 20%, var(--chrome-bg-hover));
  color: #8b5cf6;
}
.badge-blue {
  background: color-mix(in srgb, #3b82f6 20%, var(--chrome-bg-hover));
  color: #3b82f6;
}
.badge-green {
  background: color-mix(in srgb, #22c55e 20%, var(--chrome-bg-hover));
  color: #22c55e;
}
.badge-yellow {
  background: color-mix(in srgb, #eab308 20%, var(--chrome-bg-hover));
  color: #eab308;
}
.badge-red {
  background: color-mix(in srgb, #ef4444 20%, var(--chrome-bg-hover));
  color: #ef4444;
}
.badge-indigo {
  background: color-mix(in srgb, #6366f1 20%, var(--chrome-bg-hover));
  color: #6366f1;
}
.badge-orange {
  background: color-mix(in srgb, #f97316 20%, var(--chrome-bg-hover));
  color: #f97316;
}
.badge-cyan {
  background: color-mix(in srgb, #06b6d4 20%, var(--chrome-bg-hover));
  color: #06b6d4;
}
.badge-neutral {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text-dim);
}

.badge-muted {
  background: transparent;
  color: var(--chrome-text-dim);
  opacity: 0.7;
}
.badge-mono {
  font-family: ui-monospace, monospace;
  font-size: 0.75rem;
}
</style>
