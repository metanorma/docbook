<template>
  <header v-if="hasMeta" class="title-page">
    <!-- Atmospheric background -->
    <div class="title-page-atmosphere"></div>

    <!-- Cover hero image -->
    <div v-if="coverSrc" class="title-cover-hero">
      <img :src="coverSrc" :alt="`${title} cover`" class="title-cover-img" />
      <div class="title-cover-overlay"></div>
    </div>

    <div class="title-page-content" :class="{ 'title-page-content--over-cover': coverSrc }">
      <!-- Type badge -->
      <div v-if="sectionCount > 0" class="title-page-badge title-page-animate" style="--entrance-delay: 0">
        <span class="badge-dot"></span>
        {{ sectionCount }} {{ sectionCount === 1 ? 'section' : 'sections' }}
      </div>

      <h1 class="title-page-heading title-page-animate" style="--entrance-delay: 1">{{ title }}</h1>

      <!-- Decorative ornament -->
      <div class="title-page-ornament title-page-animate" style="--entrance-delay: 2">
        <span class="ornament-line"></span>
        <span class="ornament-diamond">&#9670;</span>
        <span class="ornament-line"></span>
      </div>

      <p v-if="subtitle" class="title-page-subtitle title-page-animate" style="--entrance-delay: 3">{{ subtitle }}</p>
      <p v-if="author" class="title-page-author title-page-animate" style="--entrance-delay: 4">{{ author }}</p>

      <div v-if="pubdate || copyright" class="title-page-meta title-page-animate" style="--entrance-delay: 5">
        <span v-if="pubdate">{{ pubdate }}</span>
        <span v-if="pubdate && copyright" class="meta-sep">·</span>
        <span v-if="copyright">{{ copyright }}</span>
      </div>
    </div>

    <!-- Bottom fade to content -->
    <div class="title-page-footer-gradient"></div>
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  title: string
  subtitle?: string
  author?: string
  pubdate?: string
  copyright?: string
  cover?: string
  sectionCount?: number
}>(), {
  sectionCount: 0,
})

const hasMeta = computed(() => props.subtitle || props.author || props.pubdate || props.copyright || props.cover)

const coverSrc = computed(() => {
  if (!props.cover) return null
  if (props.cover.startsWith('data:') || props.cover.startsWith('/') || props.cover.startsWith('http')) {
    return props.cover
  }
  return props.cover
})
</script>

<style scoped>
.title-page {
  position: relative;
  text-align: center;
  margin-bottom: 2rem;
  overflow: hidden;
}

/* Atmospheric background */
.title-page-atmosphere {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse 80% 60% at 30% 20%, color-mix(in srgb, var(--ebook-accent) 5%, transparent), transparent),
    radial-gradient(ellipse 60% 50% at 70% 30%, color-mix(in srgb, var(--ebook-accent) 3%, transparent), transparent);
  pointer-events: none;
  z-index: 0;
}

.title-page-atmosphere::after {
  content: '';
  position: absolute;
  inset: 0;
  background: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
  opacity: 0.35;
}

.title-page-content {
  position: relative;
  z-index: 1;
  padding: 5rem 1rem 3rem;
  border-bottom: 1px solid var(--ebook-border);
}

.title-page-content--over-cover {
  padding-top: 1.5rem;
}

/* Badge */
.title-page-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.6rem;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ebook-accent);
  padding: 4px 12px;
  border: 1px solid color-mix(in srgb, var(--ebook-accent) 25%, transparent);
  border-radius: 999px;
  margin-bottom: 1.25rem;
}

.badge-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--ebook-accent);
  animation: badge-pulse 2.5s ease-in-out infinite;
}

@keyframes badge-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

/* Cover hero */
.title-cover-hero {
  position: relative;
  width: calc(100% + 4rem);
  margin-left: -2rem;
  max-height: 360px;
  overflow: hidden;
  z-index: 1;
}

.title-cover-img {
  width: 100%;
  height: 100%;
  max-height: 360px;
  object-fit: cover;
  display: block;
}

.title-cover-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 60%;
  background: linear-gradient(to top, var(--ebook-bg), transparent);
  pointer-events: none;
}

.title-cover-hero::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at center, transparent 40%, color-mix(in srgb, var(--ebook-bg) 20%, transparent) 100%);
  z-index: 1;
  pointer-events: none;
}

/* Heading */
.title-page-heading {
  font-family: 'Playfair Display', Georgia, 'Times New Roman', serif;
  font-size: 2.75rem;
  font-weight: 700;
  line-height: 1.1;
  letter-spacing: -0.025em;
  color: var(--ebook-text-heading);
  margin: 0 0 0.75rem;
}

/* Ornament */
.title-page-ornament {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin: 0.75rem 0 1.25rem;
}

.ornament-line {
  width: 56px;
  height: 1px;
  background: linear-gradient(to right, transparent, color-mix(in srgb, var(--ebook-accent) 60%, var(--ebook-border)));
}

.ornament-line:last-child {
  background: linear-gradient(to left, transparent, color-mix(in srgb, var(--ebook-accent) 60%, var(--ebook-border)));
}

.ornament-diamond {
  font-size: 0.45rem;
  color: var(--ebook-accent);
  opacity: 0.45;
  line-height: 1;
}

.title-page-subtitle {
  font-size: 1.15rem;
  color: var(--ebook-text-muted);
  margin: 0 0 1.5rem;
  font-style: italic;
  line-height: 1.5;
}

.title-page-author {
  font-family: 'DM Sans', system-ui, sans-serif;
  font-size: 1rem;
  color: var(--ebook-text);
  margin: 0 0 0.35rem;
  font-weight: 600;
  letter-spacing: 0.01em;
}

.title-page-meta {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.72rem;
  color: var(--ebook-text-muted);
  margin-top: 1rem;
  letter-spacing: 0.02em;
}

.meta-sep {
  opacity: 0.4;
}

/* Footer gradient */
.title-page-footer-gradient {
  position: relative;
  z-index: 1;
  height: 2rem;
  background: linear-gradient(to bottom, color-mix(in srgb, var(--ebook-bg) 50%, transparent), transparent);
  pointer-events: none;
}

/* Staggered entrance animation */
.title-page-animate {
  animation: title-entrance 0.7s cubic-bezier(0.16, 1, 0.3, 1) both;
  animation-delay: calc(var(--entrance-delay, 0) * 100ms);
}

/* Heading shimmer on cover hero */
.title-page-content--over-cover .title-page-heading {
  background: linear-gradient(
    90deg,
    var(--ebook-text-heading) 0%,
    var(--ebook-text-heading) 40%,
    color-mix(in srgb, var(--ebook-accent) 30%, var(--ebook-text-heading)) 50%,
    var(--ebook-text-heading) 60%,
    var(--ebook-text-heading) 100%
  );
  background-size: 200% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: title-entrance 0.7s cubic-bezier(0.16, 1, 0.3, 1) both,
             title-shimmer 4s ease-out 0.6s 1 both;
}

@keyframes title-shimmer {
  from { background-position: 100% 0; }
  to { background-position: -100% 0; }
}

@keyframes title-entrance {
  from {
    opacity: 0;
    transform: translateY(16px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 640px) {
  .title-page-heading { font-size: 2rem; }
  .title-page-content { padding: 3rem 1rem 2rem; }
}
</style>
