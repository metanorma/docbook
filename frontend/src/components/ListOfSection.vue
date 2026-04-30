<template>
  <div class="list-of-sections" v-if="hasAny">
    <section v-for="group in listGroups" :key="group.key" class="list-of-group">
      <div class="list-of-header">
        <span class="list-of-badge">{{ group.badge }}</span>
        <h2 class="list-of-heading">{{ group.heading }}</h2>
      </div>
      <ul class="list-of-entries">
        <li v-for="entry in group.items" :key="entry.id || entry.title" class="list-of-item">
          <a v-if="entry.id" href="#" class="list-of-link" @click.prevent="scrollToEntry(entry.id)">
            <span v-if="entry.number" class="list-of-number">{{ entry.number }}</span>
            <span class="list-of-title">{{ entry.title }}</span>
            <span class="list-of-section" v-if="entry.section_title">{{ entry.section_title }}</span>
          </a>
          <span v-else class="list-of-plain">
            <span v-if="entry.number" class="list-of-number">{{ entry.number }}</span>
            {{ entry.title }}
          </span>
        </li>
      </ul>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { ListOfData } from '@/stores/documentStore'

const props = defineProps<{
  listOf: ListOfData
}>()

const figures = computed(() => props.listOf?.figures || [])
const tables = computed(() => props.listOf?.tables || [])
const examples = computed(() => props.listOf?.examples || [])

const listGroups = computed(() => [
  { key: 'figures', heading: 'List of Figures', badge: 'Fig', items: figures.value },
  { key: 'tables', heading: 'List of Tables', badge: 'Tbl', items: tables.value },
  { key: 'examples', heading: 'List of Examples', badge: 'Ex', items: examples.value },
].filter(g => g.items?.length))

const hasAny = computed(() => listGroups.value.length > 0)

function scrollToEntry(id: string) {
  const el = document.getElementById(id)
  if (el) {
    const container = el.closest('.overflow-y-auto, .overflow-auto') as HTMLElement
    if (container) {
      const containerRect = container.getBoundingClientRect()
      const elRect = el.getBoundingClientRect()
      const offset = elRect.top - containerRect.top + container.scrollTop - 70
      container.scrollTo({ top: offset, behavior: 'smooth' })
    } else {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
    history.replaceState(null, '', `#${id}`)
  }
}
</script>

<style scoped>
.list-of-sections {
  margin-top: 2.5rem;
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.list-of-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 0.75rem;
  padding-bottom: 0.6rem;
  border-bottom: 1px solid var(--ebook-border);
}

.list-of-badge {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.6rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--ebook-accent) 12%, transparent);
  color: var(--ebook-accent);
}

.list-of-heading {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--ebook-text-heading);
  margin: 0;
}

.list-of-entries {
  list-style: none;
  padding: 0;
  margin: 0;
}

.list-of-item {
  padding: 0.4rem 0;
  font-size: 0.88rem;
}

.list-of-link {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  color: var(--ebook-link, #2563eb);
  text-decoration: none;
  padding: 2px 6px;
  margin: -2px -6px;
  border-radius: 4px;
  transition: background 0.15s ease, color 0.15s ease;
}

.list-of-link:hover {
  background: color-mix(in srgb, var(--ebook-accent) 8%, transparent);
  text-decoration: none;
}

.list-of-link:active {
  background: color-mix(in srgb, var(--ebook-accent) 15%, transparent);
}

.list-of-plain {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  color: var(--ebook-text);
  padding: 2px 6px;
}

.list-of-number {
  color: var(--ebook-text-muted);
  font-variant-numeric: tabular-nums;
  font-size: 0.82rem;
  min-width: 2.5em;
  flex-shrink: 0;
}

.list-of-title {
  flex: 1;
}

.list-of-section {
  color: var(--ebook-text-muted);
  font-size: 0.8rem;
  white-space: nowrap;
  flex-shrink: 0;
}

.list-of-section::before {
  content: '—';
  margin-right: 0.35rem;
  opacity: 0.5;
}
</style>
