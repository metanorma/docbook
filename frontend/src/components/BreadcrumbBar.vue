<template>
  <nav class="breadcrumb-bar" v-if="ancestorChain.length > 0">
    <div class="breadcrumb-inner">
      <div class="breadcrumb-track">
        <template v-for="(item, index) in ancestorChain" :key="item.id">
          <svg v-if="index > 0" class="breadcrumb-sep" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
          </svg>

          <a :href="'#' + item.id"
             class="breadcrumb-chip"
             :class="item.isLeaf ? 'breadcrumb-chip--active' : ''">

            <span v-if="getTypeLabel(item.type)"
                  class="breadcrumb-badge"
                  :class="getTypeBadgeClass(item.type)">
              {{ getTypeLabel(item.type) }}
            </span>

            <span v-if="item.number"
                  class="breadcrumb-number"
                  :class="isCollapsed(item, index) ? 'breadcrumb-number--prominent' : ''">
              {{ item.number }}
            </span>

            <span class="breadcrumb-title"
                  :class="{
                    'breadcrumb-title--expanded': !isCollapsed(item, index),
                    'breadcrumb-title--active': item.isLeaf
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
  top: 48px;
  z-index: 10;
  background: var(--chrome-bg-glass);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid color-mix(in srgb, var(--chrome-border) 60%, transparent);
  transition: background 0.2s ease;
}

.breadcrumb-inner {
  max-width: 48rem;
  margin: 0 auto;
  padding: 6px 24px;
}

.breadcrumb-track {
  display: flex;
  align-items: center;
  gap: 4px;
  overflow-x: auto;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.breadcrumb-track::-webkit-scrollbar { display: none; }

.breadcrumb-sep {
  width: 12px;
  height: 12px;
  flex-shrink: 0;
  color: var(--chrome-text-dim);
  opacity: 0.35;
}

.breadcrumb-chip {
  display: flex;
  align-items: center;
  gap: 5px;
  border-radius: 6px;
  padding: 4px 8px;
  background: color-mix(in srgb, var(--chrome-text) 4%, transparent);
  text-decoration: none;
  flex-shrink: 0;
  transition: background 0.12s ease;
}

.breadcrumb-chip:hover {
  background: var(--chrome-bg-hover);
}

.breadcrumb-chip--active {
  background: color-mix(in srgb, var(--chrome-accent) 10%, transparent);
  outline: 1px solid color-mix(in srgb, var(--chrome-accent) 18%, transparent);
  outline-offset: -1px;
}

.breadcrumb-chip--active:hover {
  background: color-mix(in srgb, var(--chrome-accent) 18%, transparent);
}

.breadcrumb-badge {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.48rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 1px 4px;
  border-radius: 3px;
  flex-shrink: 0;
}

.breadcrumb-number {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.68rem;
  color: var(--chrome-text-dim);
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
}

.breadcrumb-number--prominent {
  color: var(--chrome-text);
  font-weight: 600;
}

.breadcrumb-title {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 0.78rem;
  font-weight: 500;
  color: var(--chrome-text);
  white-space: nowrap;
  max-width: 0;
  opacity: 0;
  overflow: hidden;
  transition: max-width 0.2s ease-out, opacity 0.15s ease-out, margin-left 0.15s ease-out;
  margin-left: 0;
}

.breadcrumb-title--expanded,
.breadcrumb-chip:hover .breadcrumb-title {
  max-width: 180px;
  opacity: 1;
  margin-left: 3px;
}

.breadcrumb-title--active {
  font-weight: 600;
}

/* Badge colors */
.badge-purple { background: color-mix(in srgb, #8b5cf6 15%, transparent); color: #8b5cf6; }
.badge-blue { background: color-mix(in srgb, #3b82f6 15%, transparent); color: #3b82f6; }
.badge-green { background: color-mix(in srgb, #22c55e 15%, transparent); color: #22c55e; }
.badge-yellow { background: color-mix(in srgb, #eab308 15%, transparent); color: #eab308; }
.badge-red { background: color-mix(in srgb, #ef4444 15%, transparent); color: #ef4444; }
.badge-indigo { background: color-mix(in srgb, #6366f1 15%, transparent); color: #6366f1; }
.badge-orange { background: color-mix(in srgb, #f97316 15%, transparent); color: #f97316; }
.badge-cyan { background: color-mix(in srgb, #06b6d4 15%, transparent); color: #06b6d4; }
.badge-refentry { background: transparent; color: var(--chrome-text-dim); font-family: 'JetBrains Mono', ui-monospace, monospace; font-size: 0.65rem; }
.badge-default { background: transparent; color: var(--chrome-text-dim); }

@media (max-width: 640px) {
  .breadcrumb-inner { padding: 4px 12px; }
  .breadcrumb-title--expanded { max-width: 100px; }
}
</style>
