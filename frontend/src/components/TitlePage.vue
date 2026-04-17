<template>
  <header v-if="hasMeta" class="title-page">
    <h1 class="title-page-heading">{{ title }}</h1>
    <p v-if="subtitle" class="title-page-subtitle">{{ subtitle }}</p>
    <p v-if="author" class="title-page-author">{{ author }}</p>
    <p v-if="pubdate" class="title-page-date">{{ pubdate }}</p>
    <p v-if="copyright" class="title-page-copyright">{{ copyright }}</p>
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  title: string
  subtitle?: string
  author?: string
  pubdate?: string
  copyright?: string
}>()

const hasMeta = computed(() => props.subtitle || props.author || props.pubdate || props.copyright)
</script>

<style scoped>
.title-page {
  text-align: center;
  padding: 3rem 1rem 2.5rem;
  margin-bottom: 2rem;
  border-bottom: 1px solid var(--ebook-border);
}

.title-page-heading {
  font-size: 2.25rem;
  font-weight: 800;
  line-height: 1.15;
  letter-spacing: -0.02em;
  color: var(--ebook-text-heading);
  margin: 0 0 0.5rem;
}

.title-page-subtitle {
  font-size: 1.15rem;
  color: var(--ebook-text-muted);
  margin: 0 0 1.5rem;
  font-style: italic;
}

.title-page-author {
  font-size: 1rem;
  color: var(--ebook-text);
  margin: 0 0 0.35rem;
  font-weight: 500;
}

.title-page-date {
  font-size: 0.85rem;
  color: var(--ebook-text-muted);
  margin: 0 0 0.25rem;
}

.title-page-copyright {
  font-size: 0.75rem;
  color: var(--ebook-text-muted);
  margin: 0.75rem 0 0;
  opacity: 0.7;
}
</style>
