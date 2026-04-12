<template>
  <div class="ebook-container" :class="[themeClass]">
    <slot></slot>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore } from '@/composables/useEbookStore'

const ebookStore = useEbookStore()
const themeClass = computed(() => `theme-${ebookStore.theme}`)
</script>

<style>
/* Theme: Day */
.theme-day {
  --ebook-bg: #ffffff;
  --ebook-bg-secondary: #f9fafb;
  --ebook-text: #1f2937;
  --ebook-text-muted: #6b7280;
  --ebook-accent: #0891b2;
  --ebook-accent-light: #ecfeff;
  --ebook-border: #e5e7eb;
  --ebook-code-bg: #1f2937;
  --ebook-code-text: #e5e7eb;
  --ebook-example-bg: #f0fdf4;
  --ebook-example-border: #22c55e;
  --ebook-reference-accent: #0891b2;
  --ebook-reference-bg: rgba(8, 145, 178, 0.03);
  --ebook-reference-name: #0e7490;
  --ebook-reference-badge-bg: #f3f4f6;
  --ebook-reference-badge-text: #6b7280;
}

/* Theme: Sepia */
.theme-sepia {
  --ebook-bg: #fdf6e3;
  --ebook-bg-secondary: #f5efe0;
  --ebook-text: #5c5347;
  --ebook-text-muted: #8b7355;
  --ebook-accent: #b8860b;
  --ebook-accent-light: #fef9e7;
  --ebook-border: #e0d5c0;
  --ebook-code-bg: #3d3d3d;
  --ebook-code-text: #f5f5dc;
  --ebook-example-bg: #f0ead6;
  --ebook-example-border: #8b7355;
  --ebook-reference-accent: #b8860b;
  --ebook-reference-bg: rgba(184, 134, 11, 0.05);
  --ebook-reference-name: #8b6914;
  --ebook-reference-badge-bg: #e8dcc8;
  --ebook-reference-badge-text: #6b5d4d;
}

.theme-sepia body,
.theme-sepia {
  background-color: var(--ebook-bg);
  color: var(--ebook-text);
}

/* Theme: Night */
.theme-night {
  --ebook-bg: #111827;
  --ebook-bg-secondary: #1f2937;
  --ebook-text: #e5e7eb;
  --ebook-text-muted: #9ca3af;
  --ebook-accent: #22d3ee;
  --ebook-accent-light: rgba(34, 211, 238, 0.1);
  --ebook-border: #374151;
  --ebook-code-bg: #030712;
  --ebook-code-text: #e5e7eb;
  --ebook-example-bg: rgba(34, 197, 94, 0.1);
  --ebook-example-border: #22c55e;
  --ebook-reference-accent: #22d3ee;
  --ebook-reference-bg: rgba(34, 211, 238, 0.05);
  --ebook-reference-name: #22d3ee;
  --ebook-reference-badge-bg: #374151;
  --ebook-reference-badge-text: #9ca3af;
}

.theme-night body,
.theme-night {
  background-color: var(--ebook-bg);
  color: var(--ebook-text);
}

/* Theme: OLED */
.theme-oled {
  --ebook-bg: #000000;
  --ebook-bg-secondary: #0a0a0a;
  --ebook-text: #ffffff;
  --ebook-text-muted: #a1a1aa;
  --ebook-accent: #60a5fa;
  --ebook-accent-light: rgba(96, 165, 250, 0.1);
  --ebook-border: #27272a;
  --ebook-code-bg: #18181b;
  --ebook-code-text: #fafafa;
  --ebook-example-bg: rgba(34, 197, 94, 0.05);
  --ebook-example-border: #22c55e;
  --ebook-reference-accent: #60a5fa;
  --ebook-reference-bg: rgba(96, 165, 250, 0.03);
  --ebook-reference-name: #60a5fa;
  --ebook-reference-badge-bg: #27272a;
  --ebook-reference-badge-text: #a1a1aa;
}

.theme-oled body,
.theme-oled {
  background-color: var(--ebook-bg);
  color: var(--ebook-text);
}

/* Apply theme variables to body */
body {
  background-color: var(--ebook-bg, #ffffff);
  color: var(--ebook-text, #1f2937);
  transition: background-color 0.2s ease, color 0.2s ease;
}

/* Content area styling */
.ebook-container {
  font-size: var(--ebook-font-size, 18px);
  font-weight: var(--ebook-font-weight, 400);
  line-height: var(--ebook-line-height, 1.6);
}

.ebook-container.theme-day {
  --bg: var(--ebook-bg);
  --text: var(--ebook-text);
}

.ebook-container.theme-sepia {
  --bg: var(--ebook-bg);
  --text: var(--ebook-text);
}

.ebook-container.theme-night {
  --bg: var(--ebook-bg);
  --text: var(--ebook-text);
}

.ebook-container.theme-oled {
  --bg: var(--ebook-bg);
  --text: var(--ebook-text);
}
</style>
