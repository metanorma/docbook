<template>
  <div class="library" :class="{ 'library--dark': dark }">
    <!-- Atmospheric background -->
    <div class="library__atmosphere"></div>

    <!-- Hero -->
    <header class="library__hero">
      <div class="library__hero-inner">
        <div class="library__hero-label">
          <span class="library__hero-dot"></span>
          Collection
        </div>
        <h1 class="library__title">{{ collectionStore.collectionName }}</h1>
        <div class="library__hero-meta">
          <span class="library__hero-stat">{{ collectionStore.books.length }} {{ collectionStore.books.length === 1 ? 'volume' : 'volumes' }}</span>
          <span class="library__hero-divider">·</span>
          <span class="library__hero-stat">{{ totalSections }} sections</span>
          <span class="library__hero-divider">·</span>
          <span class="library__hero-stat">{{ estimatedReadingTime }} min est. read</span>
        </div>
      </div>

      <div class="library__controls">
        <div class="library__search">
          <svg class="library__search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input
            v-model="searchQuery"
            type="text"
            class="library__search-input"
            placeholder="Filter books..."
          />
          <button v-if="searchQuery" @click="searchQuery = ''" class="library__search-clear">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
        <button
          class="library__view-toggle"
          :class="{ 'library__view-toggle--active': viewMode === 'grid' }"
          @click="viewMode = 'grid'"
          aria-label="Grid view"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="3" y="3" width="7" height="7" rx="1.5" />
            <rect x="14" y="3" width="7" height="7" rx="1.5" />
            <rect x="3" y="14" width="7" height="7" rx="1.5" />
            <rect x="14" y="14" width="7" height="7" rx="1.5" />
          </svg>
        </button>
        <button
          class="library__view-toggle"
          :class="{ 'library__view-toggle--active': viewMode === 'list' }"
          @click="viewMode = 'list'"
          aria-label="List view"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <line x1="4" y1="6" x2="20" y2="6" />
            <line x1="4" y1="12" x2="20" y2="12" />
            <line x1="4" y1="18" x2="20" y2="18" />
          </svg>
        </button>
      </div>
    </header>

    <!-- Keyboard hints -->
    <div class="library__hints">
      <span class="library__hint"><kbd>/</kbd> Search</span>
      <span class="library__hint"><kbd>?</kbd> Shortcuts</span>
    </div>

    <!-- Book Grid -->
    <main class="library__content" :class="`library__content--${viewMode}`">
      <TransitionGroup name="book">
        <BookCard
          v-for="(book, index) in filteredBooks"
          :key="book.id"
          :book="book"
          :layout="viewMode"
          :section-count="bookSections(book.id)"
          :style="{ '--stagger-delay': `${index * 60}ms` }"
          @select="openBook"
        />
      </TransitionGroup>
    </main>

    <!-- No results -->
    <div v-if="searchQuery && filteredBooks.length === 0 && collectionStore.books.length > 0" class="library__empty">
      <div class="library__empty-icon-wrap">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
      </div>
      <h3 class="library__empty-title">No matching books</h3>
      <p class="library__empty-text">Try a different search term.</p>
    </div>

    <!-- Empty State -->
    <div v-if="collectionStore.books.length === 0" class="library__empty">
      <div class="library__empty-icon-wrap">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
          <path d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
        </svg>
      </div>
      <h3 class="library__empty-title">Your library is empty</h3>
      <p class="library__empty-text">Add DocBook documents to begin your collection.</p>
    </div>

    <!-- Footer -->
    <footer class="library__footer">
      <span>Powered by <a href="https://github.com/metanorma/metanorma-docbook" class="library__footer-link">Metanorma DocBook</a></span>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useCollectionStore, type BookMeta } from '@/stores/collectionStore'
import BookCard from '@/components/library/BookCard.vue'

const props = defineProps<{ dark?: boolean }>()
const collectionStore = useCollectionStore()
const viewMode = ref<'grid' | 'list'>('grid')
const searchQuery = ref('')

const filteredBooks = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return collectionStore.books
  return collectionStore.books.filter(b =>
    b.title.toLowerCase().includes(q) ||
    (b.author && b.author.toLowerCase().includes(q))
  )
})

// Extract section counts from inline book data
function bookSections(bookId: string): number {
  const book = collectionStore.books.find(b => b.id === bookId) as (BookMeta & { data?: any }) | undefined
  if (!book) return 0
  const data = collectionStore.getPrefetchedData(bookId) || (book as any).data
  return data?.toc?.sections?.length || 0
}

const totalSections = computed(() => {
  let total = 0
  for (const book of collectionStore.books) {
    total += bookSections(book.id)
  }
  return total
})

const estimatedReadingTime = computed(() => {
  // Rough estimate: ~3 min per section
  return totalSections.value * 3
})

const emit = defineEmits<{
  openBook: [book: BookMeta]
}>()

function openBook(book: BookMeta) {
  collectionStore.selectBook(book.id)
  emit('openBook', book)
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=DM+Sans:wght@300;400;500;600&family=DM+Mono:wght@400;500&display=swap');

.library {
  --lib-bg: #f6f4f0;
  --lib-surface: #ffffff;
  --lib-surface-alt: #eeece7;
  --lib-text: #1a1a1a;
  --lib-text-secondary: #5c5c5c;
  --lib-text-muted: #8a8a8a;
  --lib-border: #e0ddd7;
  --lib-accent: #8b5e3c;
  --lib-accent-light: rgba(139, 94, 60, 0.08);
  --lib-display: 'Playfair Display', Georgia, 'Times New Roman', serif;
  --lib-body: 'DM Sans', system-ui, sans-serif;
  --lib-mono: 'DM Mono', 'JetBrains Mono', monospace;

  position: relative;
  padding: 0 48px 48px;
  background: var(--lib-bg);
  color: var(--lib-text);
  height: 100vh;
  overflow-y: auto;
  transition: background 0.3s ease, color 0.3s ease;
}

.library--dark {
  --lib-bg: #141416;
  --lib-surface: #1e1e22;
  --lib-surface-alt: #28282e;
  --lib-text: #e8e6e1;
  --lib-text-secondary: #a8a8a8;
  --lib-text-muted: #666;
  --lib-border: #333;
  --lib-accent: #c9956b;
  --lib-accent-light: rgba(201, 149, 107, 0.1);
}

/* Atmospheric background */
.library__atmosphere {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 50vh;
  background:
    radial-gradient(ellipse 80% 60% at 30% 20%, color-mix(in srgb, var(--lib-accent) 6%, transparent), transparent),
    radial-gradient(ellipse 60% 50% at 75% 10%, color-mix(in srgb, var(--lib-accent) 4%, transparent), transparent);
  pointer-events: none;
  z-index: 0;
}

.library__atmosphere::after {
  content: '';
  position: absolute;
  inset: 0;
  background: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
  opacity: 0.4;
}

/* Hero */
.library__hero {
  position: relative;
  z-index: 1;
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  padding: 56px 0 40px;
  margin-bottom: 12px;
}

.library__hero-inner {
  max-width: 60%;
}

.library__hero-label {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-family: var(--lib-mono);
  font-size: 0.65rem;
  font-weight: 500;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: var(--lib-accent);
  margin-bottom: 12px;
}

.library__hero-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--lib-accent);
  animation: pulse-dot 2s ease-in-out infinite;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

.library__title {
  font-family: var(--lib-display);
  font-size: 3.5rem;
  font-weight: 600;
  color: var(--lib-text);
  margin: 0;
  letter-spacing: -0.025em;
  line-height: 1.1;
}

.library__hero-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  flex-wrap: wrap;
}

.library__hero-stat {
  font-family: var(--lib-mono);
  font-size: 0.72rem;
  color: var(--lib-text-muted);
  letter-spacing: 0.02em;
}

.library__hero-divider {
  color: var(--lib-border);
  font-size: 0.8rem;
}

/* Controls */
.library__controls {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-shrink: 0;
}

.library__search {
  position: relative;
  display: flex;
  align-items: center;
}

.library__search-icon {
  position: absolute;
  left: 12px;
  width: 16px;
  height: 16px;
  color: var(--lib-text-muted);
  pointer-events: none;
}

.library__search-input {
  padding: 10px 32px 10px 36px;
  font-size: 0.85rem;
  font-family: var(--lib-body);
  background: var(--lib-surface);
  border: 1px solid var(--lib-border);
  border-radius: 10px;
  color: var(--lib-text);
  outline: none;
  width: 200px;
  transition: border-color 0.2s ease, width 0.3s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.2s ease;
}
.library__search-input::placeholder { color: var(--lib-text-muted); }
.library__search-input:focus {
  border-color: var(--lib-accent);
  width: 260px;
  box-shadow: 0 0 0 3px var(--lib-accent-light);
}

.library__search-clear {
  position: absolute;
  right: 8px;
  display: flex;
  align-items: center;
  padding: 4px;
  color: var(--lib-text-muted);
  border-radius: 4px;
  transition: color 0.15s ease;
}
.library__search-clear:hover { color: var(--lib-text); }

.library__view-toggle {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid var(--lib-border);
  border-radius: 10px;
  cursor: pointer;
  color: var(--lib-text-muted);
  transition: all 0.2s ease;
}
.library__view-toggle:hover {
  background: var(--lib-surface);
  color: var(--lib-text);
}
.library__view-toggle--active {
  background: var(--lib-text);
  color: var(--lib-bg);
  border-color: var(--lib-text);
}
.library__view-toggle svg { width: 18px; height: 18px; }

/* Hints */
.library__hints {
  position: relative;
  z-index: 1;
  display: flex;
  gap: 16px;
  padding-bottom: 28px;
  border-bottom: 1px solid var(--lib-border);
  margin-bottom: 32px;
}

.library__hint {
  font-family: var(--lib-mono);
  font-size: 0.65rem;
  color: var(--lib-text-muted);
  display: flex;
  align-items: center;
  gap: 5px;
}

.library__hint kbd {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  padding: 1px 5px;
  font-size: 0.6rem;
  font-family: var(--lib-mono);
  background: var(--lib-surface);
  border: 1px solid var(--lib-border);
  border-radius: 4px;
  line-height: 1.5;
}

/* Grid */
.library__content {
  position: relative;
  z-index: 1;
  display: grid;
  gap: 28px;
}
.library__content--grid {
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
}
.library__content--list {
  grid-template-columns: 1fr;
}

/* Book animations */
.book-enter-active {
  animation: bookFadeIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) both;
  animation-delay: var(--stagger-delay, 0ms);
}
.book-leave-active {
  animation: bookFadeOut 0.3s ease forwards;
}
@keyframes bookFadeIn {
  from { opacity: 0; transform: translateY(24px); }
  to { opacity: 1; transform: translateY(0); }
}
@keyframes bookFadeOut {
  from { opacity: 1; transform: scale(1); }
  to { opacity: 0; transform: scale(0.96); }
}

/* Empty */
.library__empty {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 96px 24px;
  text-align: center;
}
.library__empty-icon-wrap {
  width: 72px;
  height: 72px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--lib-accent-light);
  border-radius: 50%;
  margin-bottom: 24px;
}
.library__empty-icon-wrap svg {
  width: 32px;
  height: 32px;
  color: var(--lib-accent);
  opacity: 0.6;
}
.library__empty-title {
  font-family: var(--lib-display);
  font-size: 1.5rem;
  font-weight: 500;
  color: var(--lib-text);
  margin: 0 0 8px;
}
.library__empty-text {
  font-family: var(--lib-body);
  font-size: 0.95rem;
  color: var(--lib-text-muted);
  margin: 0;
}

/* Footer */
.library__footer {
  position: relative;
  z-index: 1;
  margin-top: 64px;
  padding-top: 24px;
  border-top: 1px solid var(--lib-border);
  text-align: center;
  font-family: var(--lib-mono);
  font-size: 0.65rem;
  color: var(--lib-text-muted);
  opacity: 0.6;
}
.library__footer-link {
  color: var(--lib-accent);
  text-decoration: none;
}
.library__footer-link:hover {
  text-decoration: underline;
}

/* Responsive */
@media (max-width: 768px) {
  .library { padding: 0 24px 24px; }
  .library__hero { flex-direction: column; align-items: flex-start; gap: 20px; padding: 36px 0 28px; }
  .library__hero-inner { max-width: 100%; }
  .library__title { font-size: 2.25rem; }
  .library__hints { display: none; }
  .library__content--grid { grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 16px; }
}
</style>
