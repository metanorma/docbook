<template>
  <div class="library-app" :class="themeClass">
    <LibraryIndex v-if="!collectionStore.isReading" @open-book="openBook" />
    <CollectionReader v-else />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useCollectionStore, type BookMeta } from '@/stores/collectionStore'
import { useEbookStore } from '@/composables/useEbookStore'
import LibraryIndex from '@/components/library/LibraryIndex.vue'
import CollectionReader from '@/components/library/CollectionReader.vue'

const collectionStore = useCollectionStore()
const ebookStore = useEbookStore()
const theme = ref<'light' | 'dark'>('light')

const themeClass = computed(() => ({
  'library-app--light': theme.value === 'light',
  'library-app--dark': theme.value === 'dark',
  'dark': theme.value === 'dark'
}))

function openBook(book: BookMeta) {
  // Load the book data and switch to reader
  collectionStore.selectBook(book.id)
}

onMounted(async () => {
  try {
    await collectionStore.loadFromWindow()
  } catch (e) {
    console.warn('No collection data found, showing empty library')
  }

  // Apply theme
  ebookStore.applyTheme?.()
})
</script>

<style>
/* CSS Variables - Luxury Theme */
:root {
  /* Colors - Light */
  --color-bg: #faf8f5;
  --color-surface: #ffffff;
  --color-surface-elevated: #f5f3f0;
  --color-text: #2d2d2d;
  --color-text-secondary: #5c5c5c;
  --color-text-muted: #8a8a8a;
  --color-border: #e8e4df;
  --color-accent: #b8860b;
  --color-accent-hover: #9a7209;

  /* Typography */
  --font-display: 'Cormorant Garamond', Georgia, serif;
  --font-body: 'Source Serif Pro', Georgia, serif;
  --font-ui: 'Source Sans 3', system-ui, sans-serif;
}

/* Dark Mode */
.dark {
  --color-bg: #1a1a1a;
  --color-surface: #242424;
  --color-surface-elevated: #2d2d2d;
  --color-text: #f0f0f0;
  --color-text-secondary: #b0b0b0;
  --color-text-muted: #707070;
  --color-border: #3d3d3d;
  --color-accent: #d4a84b;
  --color-accent-hover: #e5b94d;
}

.library-app {
  min-height: 100vh;
  background: var(--color-bg);
  color: var(--color-text);
  transition: background 0.3s ease, color 0.3s ease;
}

/* Global Typography Defaults */
body {
  font-family: var(--font-body);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Selection */
::selection {
  background: var(--color-accent);
  color: white;
}

/* Smooth Scrolling */
html {
  scroll-behavior: smooth;
}

/* Scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-muted);
}

/* Focus Visible */
*:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
</style>

<style scoped>
/* Google Fonts */
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500&family=Source+Sans+3:wght@300;400;500;600;700&family=Source+Serif+Pro:ital,wght@0,400;0,600;0,700;1,400&display=swap');
</style>
