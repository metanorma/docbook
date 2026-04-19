<template>
  <div class="list-of-sections mt-12 space-y-10" v-if="hasAny">
    <section v-for="group in listGroups" :key="group.key" v-if="group.items?.length" class="list-of-group">
      <h2 class="list-of-heading">{{ group.heading }}</h2>
      <ul class="list-of-entries">
        <li v-for="entry in group.items" :key="entry.id || entry.title">
          <a v-if="entry.id" :href="`#${entry.id}`" class="list-of-link">
            <span v-if="entry.number" class="list-of-number">{{ entry.number }}</span>
            {{ entry.title }}
          </a>
          <span v-else>
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

const listGroups = [
  { key: 'figures', heading: 'List of Figures', items: computed(() => props.listOf.figures) },
  { key: 'tables', heading: 'List of Tables', items: computed(() => props.listOf.tables) },
  { key: 'examples', heading: 'List of Examples', items: computed(() => props.listOf.examples) },
]

const hasAny = computed(() =>
  (props.listOf.figures?.length ?? 0) +
  (props.listOf.tables?.length ?? 0) +
  (props.listOf.examples?.length ?? 0) > 0
)
</script>

<style scoped>
.list-of-heading {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--ebook-text);
  margin-bottom: 0.75rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--ebook-border, #e2e8f0);
}

.list-of-entries {
  list-style: none;
  padding: 0;
  margin: 0;
}

.list-of-entries li {
  padding: 0.35rem 0;
  font-size: 0.9rem;
  color: var(--ebook-text);
}

.list-of-link {
  color: var(--ebook-link, #2563eb);
  text-decoration: none;
  transition: color 0.15s;
}

.list-of-link:hover {
  text-decoration: underline;
}

.list-of-number {
  color: var(--ebook-text-dim, #6b7280);
  margin-right: 0.5rem;
  font-variant-numeric: tabular-nums;
}
</style>
