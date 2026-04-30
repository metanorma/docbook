<template>
  <article
    class="book-card"
    :class="[`book-card--${layout}`, { 'book-card--has-cover': book.cover }]"
    @click="handleClick"
    @mouseenter="handleHover"
    role="button"
    tabindex="0"
    @keydown.enter="handleClick"
    @keydown.space.prevent="handleClick"
  >
    <div class="book-card__cover">
      <div v-if="book.cover" class="book-card__cover-img" :style="{ backgroundImage: `url(${book.cover})` }"></div>
      <div v-else class="book-card__cover-spine">
        <div class="book-card__spine-ornament"></div>
        <span class="book-card__spine-letter">{{ book.title.charAt(0).toUpperCase() }}</span>
        <div class="book-card__spine-ornament"></div>
      </div>

      <!-- Reading progress -->
      <div v-if="book.progress" class="book-card__progress">
        <div class="book-card__progress-fill" :style="{ width: `${book.progress}%` }"></div>
      </div>
    </div>

    <div class="book-card__body">
      <h3 class="book-card__title">{{ book.title }}</h3>
      <p v-if="book.author" class="book-card__author">{{ book.author }}</p>

      <!-- Metadata row -->
      <div class="book-card__meta" v-if="sectionCount > 0 || book.description">
        <span v-if="sectionCount > 0" class="book-card__stat">
          <svg class="book-card__stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25H12"/></svg>
          {{ sectionCount }} {{ sectionCount === 1 ? 'section' : 'sections' }}
        </span>
        <span v-if="sectionCount > 0" class="book-card__meta-dot"></span>
        <span v-if="sectionCount > 0" class="book-card__stat">
          <svg class="book-card__stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          ~{{ sectionCount * 3 }} min
        </span>
      </div>

      <p v-if="book.description && layout === 'grid'" class="book-card__desc">{{ book.description }}</p>
    </div>

    <!-- Hover overlay -->
    <div class="book-card__overlay">
      <span class="book-card__open-label">Read</span>
    </div>
  </article>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { BookMeta } from '@/stores/collectionStore'
import { useCollectionStore } from '@/stores/collectionStore'

const collectionStore = useCollectionStore()

const props = withDefaults(defineProps<{
  book: BookMeta
  layout?: 'grid' | 'list'
  sectionCount?: number
}>(), {
  layout: 'grid',
  sectionCount: 0,
})

const emit = defineEmits<{
  select: [book: BookMeta]
}>()

const loading = ref(false)

function handleClick() {
  emit('select', props.book)
}

function handleHover() {
  collectionStore.prefetchBook(props.book.id)
}
</script>

<style scoped>
.book-card {
  --card-radius: 12px;

  position: relative;
  display: flex;
  flex-direction: column;
  background: var(--lib-surface, #fff);
  border-radius: var(--card-radius);
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1),
              box-shadow 0.35s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow:
    0 1px 2px rgba(0,0,0,0.04),
    0 4px 16px rgba(0,0,0,0.03);
}

.book-card:hover,
.book-card:focus-visible {
  transform: translateY(-6px);
  box-shadow:
    0 8px 32px rgba(0,0,0,0.08),
    0 2px 8px rgba(0,0,0,0.04);
}

.book-card:focus-visible {
  outline: 2px solid var(--lib-accent, #8b5e3c);
  outline-offset: 3px;
}

/* Cover */
.book-card__cover {
  position: relative;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  background: var(--lib-surface-alt, #f0eeea);
}

.book-card__cover-img {
  width: 100%;
  height: 100%;
  background-size: cover;
  background-position: center;
  transition: transform 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}

.book-card:hover .book-card__cover-img {
  transform: scale(1.06);
}

/* Spine placeholder */
.book-card__cover-spine {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background:
    linear-gradient(170deg,
      color-mix(in srgb, var(--lib-accent, #8b5e3c) 8%, var(--lib-surface-alt, #f0eeea)) 0%,
      var(--lib-surface-alt, #f0eeea) 100%
    );
}

.book-card__spine-letter {
  font-family: var(--lib-display, 'Playfair Display', Georgia, serif);
  font-size: 3.5rem;
  font-weight: 600;
  color: color-mix(in srgb, var(--lib-accent, #8b5e3c) 50%, var(--lib-text-muted, #8a8a8a));
  line-height: 1;
  opacity: 0.5;
}

.book-card__spine-ornament {
  width: 32px;
  height: 1px;
  background: linear-gradient(to right, transparent, color-mix(in srgb, var(--lib-accent, #8b5e3c) 30%, transparent), transparent);
}

/* Progress */
.book-card__progress {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: rgba(0,0,0,0.06);
}
.book-card__progress-fill {
  height: 100%;
  background: var(--lib-accent, #8b5e3c);
  transition: width 0.3s ease;
  border-radius: 0 2px 0 0;
}

/* Body */
.book-card__body {
  padding: 16px 18px 18px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.book-card__title {
  font-family: var(--lib-display, 'Playfair Display', Georgia, serif);
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--lib-text, #1a1a1a);
  line-height: 1.3;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.book-card__author {
  font-family: var(--lib-body, 'DM Sans', system-ui, sans-serif);
  font-size: 0.8rem;
  color: var(--lib-text-muted, #8a8a8a);
  margin: 5px 0 0;
}

/* Metadata row */
.book-card__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 10px;
  flex-wrap: wrap;
}

.book-card__stat {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-family: var(--lib-mono, 'DM Mono', monospace);
  font-size: 0.62rem;
  color: var(--lib-text-muted, #8a8a8a);
  letter-spacing: 0.02em;
}

.book-card__stat-icon {
  width: 12px;
  height: 12px;
  opacity: 0.6;
}

.book-card__meta-dot {
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: var(--lib-border, #ddd);
}

.book-card__desc {
  font-family: var(--lib-body, 'DM Sans', system-ui, sans-serif);
  font-size: 0.78rem;
  color: var(--lib-text-secondary, #5c5c5c);
  margin: 8px 0 0;
  line-height: 1.55;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Hover overlay */
.book-card__overlay {
  position: absolute;
  inset: 0;
  background: color-mix(in srgb, var(--lib-text, #1a1a1a) 55%, transparent);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.3s ease;
  backdrop-filter: blur(2px);
}

.book-card:hover .book-card__overlay,
.book-card:focus-visible .book-card__overlay {
  opacity: 1;
}

.book-card__open-label {
  font-family: var(--lib-mono, 'DM Mono', monospace);
  font-size: 0.75rem;
  font-weight: 500;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: #fff;
  padding: 10px 24px;
  border: 1px solid rgba(255,255,255,0.35);
  border-radius: 6px;
  transition: background 0.15s ease, transform 0.2s ease;
}

.book-card:hover .book-card__open-label {
  background: rgba(255,255,255,0.1);
}

/* List layout */
.book-card--list {
  flex-direction: row;
  align-items: center;
  padding: 18px 22px;
  gap: 22px;
  border-radius: 10px;
}

.book-card--list .book-card__cover {
  flex-shrink: 0;
  width: 52px;
  height: 68px;
  aspect-ratio: auto;
  border-radius: 6px;
}

.book-card--list .book-card__body {
  padding: 0;
  flex: 1;
  min-width: 0;
}

.book-card--list .book-card__title {
  font-size: 1rem;
  -webkit-line-clamp: 1;
}

.book-card--list .book-card__author {
  font-size: 0.78rem;
  margin-top: 3px;
}

.book-card--list .book-card__cover-spine {
  background: linear-gradient(135deg,
    color-mix(in srgb, var(--lib-accent, #8b5e3c) 12%, var(--lib-surface-alt, #f0eeea)),
    var(--lib-surface-alt, #f0eeea));
}

.book-card--list .book-card__spine-letter {
  font-size: 1.5rem;
}

.book-card--list .book-card__overlay {
  border-radius: 10px;
}

/* Responsive */
@media (max-width: 768px) {
  .book-card__cover { aspect-ratio: 4 / 5; }
  .book-card__spine-letter { font-size: 2.5rem; }
}
</style>
