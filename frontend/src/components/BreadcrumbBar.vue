<template>
  <nav class="breadcrumb-bar">
    <div class="max-w-4xl mx-auto px-6 py-2">
      <div class="flex items-center gap-1 scroll-hidden">
        <template v-for="(item, index) in ancestorChain" :key="item.id">

          <!-- Separator chevron -->
          <svg v-if="index > 0" class="w-3 h-3 flex-shrink-0 breadcrumb-sep"
               fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
          </svg>

          <!-- Breadcrumb chip -->
          <a :href="'#' + item.id"
             class="group breadcrumb-chip"
             :class="item.isLeaf ? 'breadcrumb-chip-active' : ''">

            <!-- Type badge -->
            <span v-if="getTypeLabel(item.type)"
                  class="text-[10px] font-bold uppercase tracking-wider px-1 py-0.5 rounded-sm flex-shrink-0"
                  :class="getTypeBadgeClass(item.type)">
              {{ getTypeLabel(item.type) }}
            </span>

            <!-- Number -->
            <span v-if="item.number"
                  class="breadcrumb-number flex-shrink-0"
                  :class="isCollapsed(item, index) ? 'breadcrumb-number-prominent' : ''">
              {{ item.number }}
            </span>

            <!-- Title (conditionally expanded) -->
            <span class="breadcrumb-title"
                  :class="{
                    'expanded': !isCollapsed(item, index),
                    'breadcrumb-title-active': item.isLeaf
                  }">
              {{ item.title }}
            </span>
          </a>
        </template>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { type AncestorItem, getTypeLabel, getTypeBadgeClass } from '@/utils/breadcrumb'

defineProps<{
  ancestorChain: AncestorItem[]
}>()

function isCollapsed(item: AncestorItem, index: number): boolean {
  return index > 0 && !item.isLeaf
}
</script>

<style scoped>
.breadcrumb-bar {
  position: sticky;
  top: 0;
  z-index: 10;
  background: var(--chrome-bg-glass);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--chrome-border);
  transition: background 0.2s ease;
}

.breadcrumb-sep {
  color: var(--chrome-text-dim);
  opacity: 0.5;
}

.breadcrumb-chip {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  border-radius: 0.375rem;
  padding: 0.25rem 0.5rem;
  background: var(--chrome-bg-hover);
  transition: all 0.2s ease-out;
  flex-shrink: 0;
  text-decoration: none;
}

.breadcrumb-chip:hover {
  background: var(--chrome-bg-alt);
}

.breadcrumb-chip-active {
  background: var(--chrome-accent);
  background: color-mix(in srgb, var(--chrome-accent) 15%, transparent);
  outline: 1px solid color-mix(in srgb, var(--chrome-accent) 30%, transparent);
  outline-offset: -1px;
}

.breadcrumb-chip-active:hover {
  background: color-mix(in srgb, var(--chrome-accent) 25%, transparent);
}

.breadcrumb-number {
  font-size: 0.75rem;
  font-family: ui-monospace, monospace;
  color: var(--chrome-text-dim);
}

.breadcrumb-number-prominent {
  color: var(--chrome-text);
  font-weight: 500;
}

.breadcrumb-title {
  display: inline-block;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--chrome-text);
  white-space: nowrap;
  max-width: 0;
  opacity: 0;
  overflow: hidden;
  transition: max-width 0.25s ease-out, opacity 0.2s ease-out, margin-left 0.2s ease-out;
  margin-left: 0;
}

.breadcrumb-title.expanded,
.group:hover .breadcrumb-title {
  max-width: 200px;
  opacity: 1;
  margin-left: 0.375rem;
}

.breadcrumb-title-active {
  font-weight: 600;
}

.scroll-hidden {
  scrollbar-width: none;
  -ms-overflow-style: none;
}
.scroll-hidden::-webkit-scrollbar {
  display: none;
}

.badge-purple { background: color-mix(in srgb, #8b5cf6 20%, var(--chrome-bg-hover)); color: #8b5cf6; }
.badge-blue { background: color-mix(in srgb, #3b82f6 20%, var(--chrome-bg-hover)); color: #3b82f6; }
.badge-green { background: color-mix(in srgb, #22c55e 20%, var(--chrome-bg-hover)); color: #22c55e; }
.badge-yellow { background: color-mix(in srgb, #eab308 20%, var(--chrome-bg-hover)); color: #eab308; }
.badge-red { background: color-mix(in srgb, #ef4444 20%, var(--chrome-bg-hover)); color: #ef4444; }
.badge-indigo { background: color-mix(in srgb, #6366f1 20%, var(--chrome-bg-hover)); color: #6366f1; }
.badge-orange { background: color-mix(in srgb, #f97316 20%, var(--chrome-bg-hover)); color: #f97316; }
.badge-cyan { background: color-mix(in srgb, #06b6d4 20%, var(--chrome-bg-hover)); color: #06b6d4; }
.badge-refentry { background: var(--chrome-bg-hover); color: var(--chrome-text-dim); font-family: ui-monospace, monospace; font-size: 0.75rem; }
.badge-default { background: var(--chrome-bg-hover); color: var(--chrome-text-dim); }
</style>
