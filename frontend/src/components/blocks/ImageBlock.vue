<template>
  <figure :id="block.attrs?.xml_id" class="figure-block" @click="lightboxOpen(block.attrs?.src || '', block.attrs?.alt, block.attrs?.title)">
    <div class="figure-img-wrap">
      <img :src="block.attrs?.src" :alt="block.attrs?.alt || ''" class="figure-img" loading="lazy">
      <div class="figure-zoom-hint">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"/>
        </svg>
      </div>
    </div>
    <figcaption v-if="block.attrs?.title || getNumbering(block.attrs?.xml_id)" class="figure-caption">
      <span v-if="getNumbering(block.attrs?.xml_id)" class="figure-number">Figure {{ getNumbering(block.attrs?.xml_id) }}</span>
      <span v-if="block.attrs?.title">{{ block.attrs.title }}</span>
    </figcaption>
  </figure>
</template>

<script setup lang="ts">
import { inject } from 'vue'
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'

defineProps<{ block: MirrorBlockNode }>()

const documentStore = useDocumentStore()

type LightboxOpener = (src: string, alt?: string, title?: string) => void
const lightboxOpen = inject<LightboxOpener>('lightbox', () => {})

function getNumbering(id: string | undefined): string {
  if (!id) return ''
  return documentStore.getNumbering(id)
}
</script>

<style scoped>
.figure-block {
  margin: 2rem 0;
  cursor: zoom-in;
}

.figure-img-wrap {
  position: relative;
  overflow: hidden;
  border-radius: 8px;
  background: var(--ebook-bg-secondary);
  border: 1px solid var(--ebook-border);
}

.figure-img {
  width: 100%;
  height: auto;
  display: block;
  transition: transform 0.3s ease;
}

.figure-block:hover .figure-img {
  transform: scale(1.02);
}

.figure-zoom-hint {
  position: absolute;
  bottom: 8px;
  right: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.5);
  color: #fff;
  opacity: 0;
  transition: opacity 0.2s ease;
  backdrop-filter: blur(4px);
}

.figure-block:hover .figure-zoom-hint {
  opacity: 1;
}

.figure-caption {
  display: flex;
  align-items: baseline;
  justify-content: center;
  gap: 0.35em;
  margin-top: 0.6rem;
  font-size: 0.8rem;
  color: var(--ebook-text-muted);
  font-style: italic;
  padding: 0 1rem;
}

.figure-number {
  font-weight: 600;
  font-style: normal;
  color: var(--ebook-accent);
}
</style>
