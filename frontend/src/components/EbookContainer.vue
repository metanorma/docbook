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
/* ============================================================
   Theme: Day — "Clean Sheet"
   Crisp, warm-white paper. Professional, not clinical.
   ============================================================ */
.theme-day {
  --ebook-bg: #fafaf8;
  --ebook-bg-secondary: #f3f2ef;
  --ebook-text: #1a1a1a;
  --ebook-text-muted: #6b6b6b;
  --ebook-text-heading: #0d0d0d;
  --ebook-accent: #0e7490;
  --ebook-accent-light: #ecfeff;
  --ebook-border: #e2e0dc;
  --ebook-code-bg: #1e1e1e;
  --ebook-code-text: #e5e7eb;
  --ebook-example-bg: #f0fdf4;
  --ebook-example-border: #22c55e;
  --ebook-reference-accent: #0e7490;
  --ebook-reference-bg: rgba(14, 116, 144, 0.04);
  --ebook-reference-name: #0e7490;
  --ebook-reference-badge-bg: #f3f2ef;
  --ebook-reference-badge-text: #6b6b6b;
  --ebook-link-color: #1d4ed8;
  --ebook-inline-code-bg: #f0eeea;
  --ebook-inline-code-text: #9d174d;
  --ebook-inline-code-border: #ddd9d4;

  --chrome-bg: #fafaf8;
  --chrome-bg-alt: #f3f2ef;
  --chrome-bg-hover: #eae8e4;
  --chrome-bg-glass: rgba(250, 250, 248, 0.88);
  --chrome-text: #1a1a1a;
  --chrome-text-dim: #737373;
  --chrome-border: #e2e0dc;
  --chrome-accent: #0e7490;
}

/* ============================================================
   Theme: Sepia — "Warm Library"
   Aged paper, warm lamplight, brass fixtures.
   Feels like curling up with a beloved book under a reading lamp.
   ============================================================ */
.theme-sepia {
  --ebook-bg: #f4e8d1;
  --ebook-bg-secondary: #ecddc2;
  --ebook-text: #3e2f23;
  --ebook-text-muted: #7a6652;
  --ebook-text-heading: #2a1d12;
  --ebook-accent: #b8860b;
  --ebook-accent-light: #fef3c7;
  --ebook-border: #d4c4a5;
  --ebook-code-bg: #2c2418;
  --ebook-code-text: #f0e6d0;
  --ebook-example-bg: #e8dfc8;
  --ebook-example-border: #8b7355;
  --ebook-reference-accent: #9a7209;
  --ebook-reference-bg: rgba(184, 134, 11, 0.06);
  --ebook-reference-name: #7a5a08;
  --ebook-reference-badge-bg: #dfd0b4;
  --ebook-reference-badge-text: #6b5d4d;
  --ebook-link-color: #7c3aed;
  --ebook-inline-code-bg: #e4d8be;
  --ebook-inline-code-text: #8b1a4a;
  --ebook-inline-code-border: #d0c09e;

  --chrome-bg: #f4e8d1;
  --chrome-bg-alt: #ecddc2;
  --chrome-bg-hover: #dfd0b4;
  --chrome-bg-glass: rgba(244, 232, 209, 0.88);
  --chrome-text: #3e2f23;
  --chrome-text-dim: #7a6652;
  --chrome-border: #d4c4a5;
  --chrome-accent: #b8860b;
}

.theme-sepia body,
.theme-sepia {
  background-color: var(--ebook-bg);
  color: var(--ebook-text);
}

/* ============================================================
   Theme: Night — "Midnight Study"
   Warm dark tones for comfortable extended reading.
   Inspired by a dimly-lit study room — not cold blue-gray.
   ============================================================ */
.theme-night {
  --ebook-bg: #1a1a20;
  --ebook-bg-secondary: #242430;
  --ebook-text: #ddd9d2;
  --ebook-text-muted: #8e8a82;
  --ebook-text-heading: #f0ece5;
  --ebook-accent: #38bdf8;
  --ebook-accent-light: rgba(56, 189, 248, 0.1);
  --ebook-border: #33333f;
  --ebook-code-bg: #0e0e14;
  --ebook-code-text: #ddd9d2;
  --ebook-example-bg: rgba(34, 197, 94, 0.08);
  --ebook-example-border: #22c55e;
  --ebook-reference-accent: #38bdf8;
  --ebook-reference-bg: rgba(56, 189, 248, 0.05);
  --ebook-reference-name: #38bdf8;
  --ebook-reference-badge-bg: #2a2a36;
  --ebook-reference-badge-text: #8e8a82;
  --ebook-link-color: #7dd3fc;
  --ebook-inline-code-bg: #2a2a36;
  --ebook-inline-code-text: #f0abba;
  --ebook-inline-code-border: #3a3a48;

  --chrome-bg: #242430;
  --chrome-bg-alt: #1a1a20;
  --chrome-bg-hover: #33333f;
  --chrome-bg-glass: rgba(36, 36, 48, 0.88);
  --chrome-text: #ddd9d2;
  --chrome-text-dim: #8e8a82;
  --chrome-border: #33333f;
  --chrome-accent: #38bdf8;
}

.theme-night body,
.theme-night {
  background-color: var(--ebook-bg);
  color: var(--ebook-text);
}

/* ============================================================
   Theme: OLED — "Void"
   Pure black for AMOLED efficiency.
   Slightly warm whites to reduce eye strain against pure black.
   ============================================================ */
.theme-oled {
  --ebook-bg: #000000;
  --ebook-bg-secondary: #080808;
  --ebook-text: #e8e6e1;
  --ebook-text-muted: #92908a;
  --ebook-text-heading: #f5f3ef;
  --ebook-accent: #818cf8;
  --ebook-accent-light: rgba(129, 140, 248, 0.1);
  --ebook-border: #1e1e1e;
  --ebook-code-bg: #0a0a0a;
  --ebook-code-text: #e8e6e1;
  --ebook-example-bg: rgba(34, 197, 94, 0.05);
  --ebook-example-border: #22c55e;
  --ebook-reference-accent: #818cf8;
  --ebook-reference-bg: rgba(129, 140, 248, 0.04);
  --ebook-reference-name: #818cf8;
  --ebook-reference-badge-bg: #161616;
  --ebook-reference-badge-text: #92908a;
  --ebook-link-color: #a5b4fc;
  --ebook-inline-code-bg: #141414;
  --ebook-inline-code-text: #f0abba;
  --ebook-inline-code-border: #222222;

  --chrome-bg: #080808;
  --chrome-bg-alt: #000000;
  --chrome-bg-hover: #181818;
  --chrome-bg-glass: rgba(8, 8, 8, 0.88);
  --chrome-text: #e8e6e1;
  --chrome-text-dim: #92908a;
  --chrome-border: #1e1e1e;
  --chrome-accent: #818cf8;
}

.theme-oled body,
.theme-oled {
  background-color: var(--ebook-bg);
  color: var(--ebook-text);
}

/* Apply theme variables to body */
body {
  background-color: var(--ebook-bg, #ffffff);
  color: var(--ebook-text, #1a1a1a);
  transition: background-color 0.25s ease, color 0.25s ease;
}

/* Content area styling */
.ebook-container {
  font-size: var(--ebook-font-size, 18px);
  line-height: var(--ebook-line-height, 1.6);
  text-align: var(--ebook-text-align, left);
  hyphens: var(--ebook-hyphens, manual);
}

.font-serif {
  font-family: Georgia, 'Times New Roman', serif;
}

.font-sans {
  font-family: system-ui, -apple-system, sans-serif;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .ebook-container {
    font-size: 16px;
  }
}

/* Print styles */
@media print {
  .sidebar-panel,
  .ebook-topbar,
  .settings-panel,
  .search-modal,
  .image-lightbox,
  .copy-btn,
  .anchor-link,
  .section-nav,
  .reading-progress,
  .breadcrumb-bar,
  .app-footer,
  .keyboard-help,
  .back-to-top {
    display: none !important;
  }

  main {
    padding-top: 0 !important;
    padding-left: 0 !important;
    max-width: 100% !important;
  }

  .db-content {
    max-width: 100% !important;
  }

  * {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  section {
    break-inside: avoid;
  }

  h1, h2, h3, h4 {
    break-after: avoid;
  }

  figure, table, pre, .code-block {
    break-inside: avoid;
  }

  .code-block {
    overflow: visible;
    white-space: pre-wrap;
    word-break: break-word;
  }

  body {
    color: #000;
    background: #fff;
  }
}
</style>
