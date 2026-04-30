<template>
  <li class="toc-item">
    <!-- Item with children (collapsible) -->
    <template v-if="item.children && item.children.length > 0">
      <div class="toc-row" :class="{ 'toc-row--active': isActive }">
        <button @click="toggle" class="toc-toggle" :class="{ 'toc-toggle--open': isOpen }">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
          </svg>
        </button>
        <a
          ref="linkEl"
          :href="'#' + item.id"
          class="toc-link"
          :class="linkClass"
        >
          <span v-if="typeLabel" class="toc-badge" :class="typeBadgeClass">{{ typeLabel }}</span>
          <span v-if="getNumber(item.id)" class="toc-number">{{ getNumber(item.id) }}</span>
          <span class="toc-text">{{ item.title }}</span>
          <span v-if="isRead" class="toc-read-indicator" title="Read"></span>
        </a>
      </div>
      <ul v-if="isOpen" class="toc-children">
        <TocTreeItem
          v-for="child in item.children"
          :key="child.id"
          :item="child"
          :depth="depth + 1"
          :force-open="forceOpen"
        />
      </ul>
    </template>

    <!-- Leaf item (no children) -->
    <div v-else class="toc-row" :class="{ 'toc-row--active': isActive }">
      <a
        ref="linkEl"
        :href="'#' + item.id"
        class="toc-link toc-link--leaf"
        :class="linkClass"
      >
        <span v-if="typeLabel" class="toc-badge" :class="typeBadgeClass">{{ typeLabel }}</span>
        <span v-if="getNumber(item.id)" class="toc-number">{{ getNumber(item.id) }}</span>
        <span class="toc-text">{{ item.title }}</span>
        <span v-if="isRead" class="toc-read-indicator" title="Read"></span>
      </a>
    </div>
  </li>
</template>

<script setup lang="ts">
import { ref, computed, watch, inject } from 'vue'
import { useDocumentStore, type TocItem } from '@/stores/documentStore'
import { useUiStore } from '@/stores/uiStore'
import { getTypeLabel, getTypeBadgeClass } from '@/utils/typeMetadata'
import { useReadingStats } from '@/composables/useReadingStats'

interface Props {
  item: TocItem
  depth: number
  forceOpen?: boolean
}

const props = defineProps<Props>()
const documentStore = useDocumentStore()
const uiStore = useUiStore()
const isOpen = ref(props.depth <= 1)
const linkEl = ref<HTMLElement | null>(null)

const readingStats = inject<ReturnType<typeof useReadingStats> | null>('readingStats', null)
const isRead = computed(() => readingStats?.isSectionRead(props.item.id) ?? false)
const isActive = computed(() => uiStore.activeSectionId === props.item.id)

watch(() => props.forceOpen, (val) => {
  if (val) isOpen.value = true
}, { immediate: true })

watch(() => uiStore.activeSectionId, (activeId) => {
  if (activeId && hasDescendant(props.item, activeId)) {
    isOpen.value = true
  }

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

const isFrontmatter = computed(() => {
  return ['dedication', 'acknowledgements', 'preface', 'colophon'].includes(props.item.type)
})

const linkClass = computed(() => {
  if (isActive.value) return 'toc-link--active'
  if (props.item.type === 'part') return 'toc-link--part'
  if (isFrontmatter.value) return 'toc-link--frontmatter'
  return 'toc-link--default'
})

function toggle() {
  isOpen.value = !isOpen.value
}

function getNumber(id: string): string {
  return documentStore.getNumbering(id)
}
</script>

<style scoped>
.toc-item {
  list-style: none;
}

/* Row */
.toc-row {
  display: flex;
  align-items: center;
  gap: 2px;
  border-radius: 6px;
  margin-bottom: 1px;
  position: relative;
  transition: background 0.12s ease;
}

.toc-row--active {
  background: color-mix(in srgb, var(--chrome-accent) 10%, transparent);
}

.toc-row--active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 4px;
  bottom: 4px;
  width: 3px;
  border-radius: 2px;
  background: var(--chrome-accent);
}

/* Toggle chevron */
.toc-toggle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  flex-shrink: 0;
  border-radius: 4px;
  color: var(--chrome-text-dim);
  transition: background 0.12s ease, color 0.12s ease, transform 0.15s ease;
}

.toc-toggle svg {
  width: 14px;
  height: 14px;
  transition: transform 0.15s ease;
}

.toc-toggle:hover {
  background: var(--chrome-bg-hover);
  color: var(--chrome-text);
}

.toc-toggle--open svg {
  transform: rotate(90deg);
}

/* Link */
.toc-link {
  display: flex;
  align-items: center;
  gap: 6px;
  flex: 1;
  min-width: 0;
  padding: 5px 6px;
  border-radius: 4px;
  text-decoration: none;
  font-size: 0.8rem;
  line-height: 1.35;
  transition: background 0.12s ease, color 0.12s ease;
}

.toc-link--leaf {
  padding-left: 30px;
}

.toc-link:hover {
  background: color-mix(in srgb, var(--chrome-text) 4%, transparent);
}

/* Link variants */
.toc-link--default {
  color: var(--chrome-text-dim);
}
.toc-link--default:hover { color: var(--chrome-text); }

.toc-link--active {
  color: var(--chrome-accent);
  font-weight: 600;
}
.toc-link--active:hover {
  background: color-mix(in srgb, var(--chrome-accent) 15%, transparent);
}

.toc-link--part {
  color: var(--chrome-text);
  font-weight: 600;
}

.toc-link--frontmatter {
  color: var(--chrome-text-dim);
  font-style: italic;
}

/* Badge */
.toc-badge {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.5rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  padding: 1px 5px;
  border-radius: 3px;
  flex-shrink: 0;
  white-space: nowrap;
}

/* Number */
.toc-number {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.65rem;
  color: var(--chrome-text-dim);
  min-width: 2em;
  text-align: right;
  flex-shrink: 0;
  font-variant-numeric: tabular-nums;
}

/* Text */
.toc-text {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Read indicator */
.toc-read-indicator {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--chrome-accent);
  opacity: 0.5;
  flex-shrink: 0;
  margin-left: auto;
}

.toc-link--active .toc-read-indicator {
  opacity: 0.8;
}

/* Children */
.toc-children {
  list-style: none;
  padding: 0;
  margin: 0;
  padding-left: 14px;
  position: relative;
}

/* Indentation guide line */
.toc-children::before {
  content: '';
  position: absolute;
  left: 7px;
  top: 4px;
  bottom: 4px;
  width: 1px;
  background: var(--chrome-border);
  opacity: 0.6;
}

/* Badge color variants */
.badge-purple { background: color-mix(in srgb, #8b5cf6 15%, transparent); color: #8b5cf6; }
.badge-blue { background: color-mix(in srgb, #3b82f6 15%, transparent); color: #3b82f6; }
.badge-green { background: color-mix(in srgb, #22c55e 15%, transparent); color: #22c55e; }
.badge-yellow { background: color-mix(in srgb, #eab308 15%, transparent); color: #eab308; }
.badge-red { background: color-mix(in srgb, #ef4444 15%, transparent); color: #ef4444; }
.badge-indigo { background: color-mix(in srgb, #6366f1 15%, transparent); color: #6366f1; }
.badge-orange { background: color-mix(in srgb, #f97316 15%, transparent); color: #f97316; }
.badge-cyan { background: color-mix(in srgb, #06b6d4 15%, transparent); color: #06b6d4; }
.badge-neutral { background: transparent; color: var(--chrome-text-dim); }
.badge-muted { background: transparent; color: var(--chrome-text-dim); opacity: 0.6; }
.badge-mono {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.6rem;
}
</style>
