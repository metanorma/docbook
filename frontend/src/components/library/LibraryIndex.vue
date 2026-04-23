<template>
  <div class="library">
    <!-- Header -->
    <header class="library__header">
      <div class="library__header-content">
        <h1 class="library__title">{{ collectionStore.collectionName }}</h1>
        <p class="library__subtitle">{{ collectionStore.books.length }} {{ collectionStore.books.length === 1 ? 'volume' : 'volumes' }}</p>
      </div>

      <div class="library__controls">
        <button
          class="library__view-toggle"
          :class="{ 'library__view-toggle--active': viewMode === 'grid' }"
          @click="viewMode = 'grid'"
          aria-label="Grid view"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="7" height="7" rx="1" />
            <rect x="14" y="3" width="7" height="7" rx="1" />
            <rect x="3" y="14" width="7" height="7" rx="1" />
            <rect x="14" y="14" width="7" height="7" rx="1" />
          </svg>
        </button>
        <button
          class="library__view-toggle"
          :class="{ 'library__view-toggle--active': viewMode === 'list' }"
          @click="viewMode = 'list'"
          aria-label="List view"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6" />
            <line x1="3" y1="12" x2="21" y2="12" />
            <line x1="3" y1="18" x2="21" y2="18" />
          </svg>
        </button>
      </div>
    </header>

    <!-- Book Grid -->
    <main class="library__content" :class="`library__content--${viewMode}`">
      <TransitionGroup name="book">
        <BookCard
          v-for="(book, index) in collectionStore.books"
          :key="book.id"
          :book="book"
          :style="{ '--stagger-delay': `${index * 50}ms` }"
          @select="openBook"
        />
      </TransitionGroup>
    </main>

    <!-- Empty State -->
    <div v-if="collectionStore.books.length === 0" class="library__empty">
      <svg class="library__empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
        <path d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
      </svg>
      <h3 class="library__empty-title">Your library is empty</h3>
      <p class="library__empty-text">Add DocBook documents to begin your collection.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useCollectionStore, type BookMeta } from '@/stores/collectionStore'
import BookCard from '@/components/library/BookCard.vue'

const collectionStore = useCollectionStore()
const viewMode = ref<'grid' | 'list'>('grid')

const emit = defineEmits<{
  openBook: [book: BookMeta]
}>()

function openBook(book: BookMeta) {
  collectionStore.selectBook(book.id)
  emit('openBook', book)
}
</script>

<style scoped>
.library {
  min-height: 100vh;
  padding: 48px;
  background: var(--color-bg);
}

.library__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 48px;
  padding-bottom: 24px;
  border-bottom: 1px solid var(--color-border);
}

.library__title {
  font-family: var(--font-display);
  font-size: 2.5rem;
  font-weight: 500;
  color: var(--color-text);
  margin: 0;
  letter-spacing: -0.02em;
}

.library__subtitle {
  font-family: var(--font-ui);
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin: 8px 0 0;
  letter-spacing: 0.05em;
}

.library__controls {
  display: flex;
  gap: 8px;
}

.library__view-toggle {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  cursor: pointer;
  color: var(--color-text-muted);
  transition: all 0.2s ease;
}

.library__view-toggle:hover {
  background: var(--color-surface);
  color: var(--color-text);
}

.library__view-toggle--active {
  background: var(--color-text);
  color: var(--color-bg);
  border-color: var(--color-text);
}

.library__view-toggle svg {
  width: 18px;
  height: 18px;
}

/* Grid Layout */
.library__content {
  display: grid;
  gap: 32px;
}

.library__content--grid {
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
}

.library__content--list {
  grid-template-columns: 1fr;
}

/* Book Card Animations */
.book-enter-active {
  animation: bookFadeIn 0.5s cubic-bezier(0.4, 0, 0.2, 1) both;
  animation-delay: var(--stagger-delay, 0ms);
}

.book-leave-active {
  animation: bookFadeOut 0.3s ease forwards;
}

@keyframes bookFadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes bookFadeOut {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.95);
  }
}

/* Empty State */
.library__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 96px 24px;
  text-align: center;
}

.library__empty-icon {
  width: 80px;
  height: 80px;
  color: var(--color-text-muted);
  opacity: 0.3;
  margin-bottom: 24px;
}

.library__empty-title {
  font-family: var(--font-display);
  font-size: 1.5rem;
  font-weight: 500;
  color: var(--color-text);
  margin: 0 0 8px;
}

.library__empty-text {
  font-family: var(--font-body);
  font-size: 1rem;
  color: var(--color-text-muted);
  margin: 0;
}

/* Responsive */
@media (max-width: 768px) {
  .library {
    padding: 24px;
  }

  .library__header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .library__title {
    font-size: 2rem;
  }

  .library__content--grid {
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 20px;
  }
}
</style>
