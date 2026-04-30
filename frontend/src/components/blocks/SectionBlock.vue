<template>
  <!-- Part: dramatic full-width divider -->
  <component v-if="block.type === 'part'" :is="meta.tag" :id="block.attrs?.xml_id" class="section-part">
    <div class="part-divider">
      <div class="part-divider-line"></div>
      <div v-if="getNumbering(block.attrs?.xml_id)" class="part-number">{{ getNumbering(block.attrs?.xml_id) }}</div>
    </div>
    <h1 v-if="block.attrs?.title" class="part-title heading-with-anchor">
      <a
        v-if="block.attrs?.xml_id"
        :href="`#${block.attrs.xml_id}`"
        class="anchor-link"
        @click.prevent="copyAnchor(block.attrs.xml_id)"
      >#</a>
      {{ block.attrs.title }}
    </h1>

    <!-- Content (lazy or rendered) -->
    <template v-if="!shouldLazyRender || isSectionVisible">
      <div class="part-content">
        <MirrorRenderer :blocks="block.content || []" />
      </div>
    </template>
    <div v-else class="lazy-placeholder" :data-section-id="block.attrs?.xml_id"></div>
  </component>

  <!-- Chapter: accent left border -->
  <component v-else-if="block.type === 'chapter'" :is="meta.tag" :id="block.attrs?.xml_id" class="section-chapter">
    <component
      v-if="block.attrs?.title"
      :is="meta.headingTag"
      :class="['heading-with-anchor heading-text', meta.headingClass]"
    >
      <a
        v-if="block.attrs?.xml_id && !meta.noAnchor"
        :href="`#${block.attrs.xml_id}`"
        class="anchor-link"
        @click.prevent="copyAnchor(block.attrs.xml_id)"
      >#</a>
      <span
        v-if="!meta.noNumbering && getNumbering(block.attrs?.xml_id)"
        class="muted-text mr-2"
      >{{ getNumbering(block.attrs?.xml_id) }}</span>
      {{ block.attrs.title }}
    </component>

    <template v-if="!shouldLazyRender || isSectionVisible">
      <component
        v-if="meta.contentWrapper"
        :is="meta.contentWrapper.tag"
        :class="meta.contentWrapper.class"
      >
        <MirrorRenderer :blocks="block.content || []" />
      </component>
      <MirrorRenderer v-else :blocks="block.content || []" />
    </template>
    <div v-else class="lazy-placeholder" :data-section-id="block.attrs?.xml_id"></div>
  </component>

  <!-- All other section types -->
  <component v-else :is="meta.tag" :id="block.attrs?.xml_id" :class="outerClass">
    <!-- Heading -->
    <component
      v-if="block.attrs?.title"
      :is="meta.headingTag"
      :class="['heading-with-anchor heading-text', meta.headingClass]"
    >
      <a
        v-if="block.attrs?.xml_id && !meta.noAnchor"
        :href="`#${block.attrs.xml_id}`"
        class="anchor-link"
        @click.prevent="copyAnchor(block.attrs.xml_id)"
      >#</a>
      <span
        v-if="!meta.noNumbering && getNumbering(block.attrs?.xml_id)"
        :class="['muted-text mr-2', meta.headingTag === 'h1' ? 'text-xl font-normal' : 'font-normal', meta.headingTag === 'h1' ? 'mr-3' : 'mr-2']"
      >{{ getNumbering(block.attrs?.xml_id) }}</span>
      {{ block.attrs.title }}
    </component>

    <!-- Content (lazy or rendered) -->
    <template v-if="!shouldLazyRender || isSectionVisible">
      <component
        v-if="meta.contentWrapper"
        :is="meta.contentWrapper.tag"
        :class="meta.contentWrapper.class"
      >
        <MirrorRenderer :blocks="block.content || []" />
      </component>
      <MirrorRenderer v-else :blocks="block.content || []" />
    </template>
    <div v-else class="lazy-placeholder" :data-section-id="block.attrs?.xml_id"></div>
  </component>
</template>

<script setup lang="ts">
import { computed, inject, type Ref } from 'vue'
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'
import { SECTION_META, isSectionType } from '@/utils/typeMetadata'
import { copyToClipboard } from '@/utils/clipboard'
import { useToast } from '@/composables/useToast'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

const props = defineProps<{
  block: MirrorBlockNode
}>()

const documentStore = useDocumentStore()
const { addToast } = useToast()

const meta = computed(() => {
  const m = SECTION_META[props.block.type]
  return m || SECTION_META['section']!
})

// Refentry uses article tag with border styling
const outerClass = computed(() => {
  if (props.block.type === 'refentry') {
    return 'mb-6 border border-ebook-border rounded-lg p-4'
  }
  return 'mb-6'
})

// Lazy section rendering support (provided by App.vue)
const lazyVisible = inject<(id: string) => boolean>('lazySectionVisible', () => true)
const lazyObserve = inject<(id: string) => void>('lazyObserveSection', () => {})
const lazyReady = inject<Ref<boolean>>('lazyInitialized', { value: true } as Ref<boolean>)

const shouldLazyRender = computed(() => {
  return !!(props.block.attrs?.xml_id && isSectionType(props.block.type))
})

const isSectionVisible = computed(() => {
  if (!lazyReady.value) return true
  const id = props.block.attrs?.xml_id
  if (!id) return true
  lazyObserve(id)
  return lazyVisible(id)
})

function getNumbering(id: string | undefined): string {
  if (!id) return ''
  return documentStore.getNumbering(id)
}

function copyAnchor(id: string) {
  const url = `${window.location.origin}${window.location.pathname}#${id}`
  copyToClipboard(url)
  addToast('Link copied to clipboard', 'success')
}
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.heading-text { color: var(--ebook-text-heading); }
.muted-text { color: var(--ebook-text-muted); }
.border-ebook-border { border-color: var(--ebook-border); }

.heading-with-anchor {
  position: relative;
  scroll-margin-top: 70px;
}

.anchor-link {
  position: absolute;
  left: -1.2em;
  color: var(--ebook-text-muted);
  opacity: 0;
  transition: opacity 0.15s ease;
  text-decoration: none;
  font-weight: 400;
  font-size: 0.7em;
  line-height: 1;
  vertical-align: middle;
}

.heading-with-anchor:hover .anchor-link,
.anchor-link:focus {
  opacity: 1;
}

/* ============================================================
   Part Divider — dramatic full-width section break
   ============================================================ */
.section-part {
  margin-top: 5rem;
  margin-bottom: 3rem;
  position: relative;
  animation: part-reveal 0.7s cubic-bezier(0.16, 1, 0.3, 1) both;
}

@keyframes part-reveal {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.part-divider {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.part-divider-line {
  flex: 1;
  height: 1px;
  background: linear-gradient(
    to right,
    transparent,
    var(--ebook-accent) 20%,
    var(--ebook-accent) 80%,
    transparent
  );
  opacity: 0.4;
}

.part-number {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: var(--ebook-accent);
  background: var(--ebook-bg);
  padding: 4px 14px;
  border: 1px solid var(--ebook-accent);
  border-radius: 999px;
  opacity: 0.8;
  white-space: nowrap;
}

.part-title {
  font-size: 2rem;
  font-weight: 800;
  color: var(--ebook-text-heading);
  letter-spacing: -0.01em;
  margin: 0 0 2rem;
  line-height: 1.2;
}

.part-content {
  padding-left: 0;
}

/* ============================================================
   Chapter — subtle left accent border
   ============================================================ */
.section-chapter {
  margin-bottom: 2.5rem;
  padding-left: 1.25rem;
  border-left: 2px solid var(--ebook-accent);
  opacity: 0.92;
  animation: section-reveal 0.5s cubic-bezier(0.16, 1, 0.3, 1) both;
  animation-delay: 0.1s;
}

/* Drop cap removed — clean paragraph start */

/* Section reveal animation */
@keyframes section-reveal {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Lazy placeholder */
.lazy-placeholder {
  min-height: 100px;
  background: linear-gradient(180deg, var(--ebook-bg-secondary) 0%, transparent 100%);
  border-radius: 8px;
  opacity: 0.4;
}

/* Glossary */
.glossary-list { margin-left: 0; }
.glossary-list dt { font-weight: 700; margin-top: 1rem; color: var(--ebook-text-heading); }
.glossary-list dd { margin-left: 1rem; margin-bottom: 0.5rem; color: var(--ebook-text); }

/* Procedure */
.procedure-list {
  list-style: none;
  padding-left: 0;
  counter-reset: step-counter;
}
</style>
