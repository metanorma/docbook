<template>
  <article
    class="book-card"
    :class="[`book-card--${layout}`, { 'book-card--loading': loading }]"
    @click="handleClick"
    role="button"
    tabindex="0"
    @keydown.enter="handleClick"
    @keydown.space.prevent="handleClick"
  >
    <div class="book-card__cover">
      <div v-if="book.cover" class="book-card__cover-img" :style="{ backgroundImage: `url(${book.cover})` }"></div>
      <div v-else class="book-card__cover-placeholder">
        <svg class="book-card__cover-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
        </svg>
        <span v-if="layout === 'grid'" class="book-card__cover-letter">{{ book.title.charAt(0).toUpperCase() }}</span>
      </div>

      <div v-if="book.progress" class="book-card__progress">
        <div class="book-card__progress-bar" :style="{ width: `${book.progress}%` }"></div>
      </div>
    </div>

    <div class="book-card__content">
      <h3 class="book-card__title">{{ book.title }}</h3>
      <p v-if="book.author" class="book-card__author">{{ book.author }}</p>
      <p v-if="book.description && layout === 'grid'" class="book-card__description">{{ book.description }}</p>
    </div>

    <div class="book-card__overlay">
      <span class="book-card__action">Open</span>
    </div>
  </article>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { BookMeta } from '@/stores/collectionStore'

const props = withDefaults(defineProps<{
  book: BookMeta
  layout?: 'grid' | 'list'
}>(), {
  layout: 'grid'
})

const emit = defineEmits<{
  select: [book: BookMeta]
}>()

const loading = ref(false)

function handleClick() {
  emit('select', props.book)
}
</script>

<style scoped>
.book-card {
  position: relative;
  display: flex;
  flex-direction: column;
  background: var(--color-surface);
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1),
              box-shadow 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04),
              0 4px 12px rgba(0, 0, 0, 0.03);
}

.book-card:hover,
.book-card:focus-visible {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08),
              0 16px 48px rgba(0, 0, 0, 0.04);
}

.book-card:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

/* Grid layout (default) */
.book-card__cover {
  position: relative;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  background: var(--color-surface-elevated);
}

/* List layout — horizontal */
.book-card--list {
  flex-direction: row;
  align-items: center;
  padding: 16px 20px;
  gap: 20px;
  border-radius: 8px;
}

.book-card--list .book-card__cover {
  flex-shrink: 0;
  width: 48px;
  height: 64px;
  aspect-ratio: auto;
  border-radius: 4px;
}

.book-card--list .book-card__content {
  padding: 0;
  flex: 1;
  min-width: 0;
}

.book-card--list .book-card__title {
  font-size: 1rem;
  -webkit-line-clamp: 1;
}

.book-card--list .book-card__author {
  font-size: 0.8125rem;
  margin: 2px 0 0;
}

.book-card--list .book-card__overlay {
  border-radius: 8px;
}

.book-card--list .book-card__cover-placeholder {
  background: linear-gradient(135deg,
    var(--color-surface-elevated) 0%,
    var(--color-border) 100%);
}

.book-card--list .book-card__cover-icon {
  width: 24px;
  height: 24px;
}

.book-card__cover-img {
  width: 100%;
  height: 100%;
  background-size: cover;
  background-position: center;
  transition: transform 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.book-card:hover .book-card__cover-img {
  transform: scale(1.05);
}

.book-card__cover-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg,
    var(--color-surface-elevated) 0%,
    var(--color-surface) 100%);
}

.book-card__cover-icon {
  width: 48px;
  height: 48px;
  color: var(--color-text-muted);
  opacity: 0.3;
}

.book-card__cover-letter {
  font-family: var(--font-display);
  font-size: 3rem;
  font-weight: 500;
  color: var(--color-text-muted);
  opacity: 0.4;
  margin-top: 8px;
}

.book-card__progress {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: rgba(0, 0, 0, 0.1);
}

.book-card__progress-bar {
  height: 100%;
  background: var(--color-accent);
  transition: width 0.3s ease;
}

.book-card__content {
  padding: 16px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.book-card__title {
  font-family: var(--font-display);
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text);
  line-height: 1.3;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.book-card__author {
  font-family: var(--font-body);
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin: 6px 0 0;
}

.book-card__description {
  font-family: var(--font-body);
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  margin: 8px 0 0;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.book-card__overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.book-card:hover .book-card__overlay,
.book-card:focus-visible .book-card__overlay {
  opacity: 1;
}

.book-card__action {
  font-family: var(--font-ui);
  font-size: 0.875rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: white;
  padding: 12px 24px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 4px;
  backdrop-filter: blur(4px);
}
</style>
