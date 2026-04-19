<template>
  <div class="content-blocks">
    <template v-for="(block, index) in blocks" :key="index">

      <!-- Document node - recurse into content -->
      <template v-if="block.type === 'doc'">
        <MirrorRenderer :blocks="block.content || []" />
      </template>

      <!-- All section-like types (17 types) handled by SectionBlock -->
      <SectionBlock v-else-if="isSectionType(block.type)" :block="block" />

      <!-- RefSection -->
      <div v-else-if="block.type === 'refsection'" class="mb-4">
        <h3 v-if="block.attrs?.title" class="text-base font-semibold heading-text mb-2">{{ block.attrs.title }}</h3>
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- GlossEntry -->
      <template v-else-if="block.type === 'gloss_entry'">
        <MirrorRenderer :blocks="block.content || []" />
      </template>

      <!-- GlossTerm -->
      <dt v-else-if="block.type === 'gloss_term'" class="font-bold ebook-text">
        <MirrorRenderer :blocks="block.content || []" />
      </dt>

      <!-- GlossDef -->
      <dd v-else-if="block.type === 'gloss_def'" class="ml-4 mb-2 ebook-text">
        <MirrorRenderer :blocks="block.content || []" />
      </dd>

      <!-- GlossSee -->
      <dd v-else-if="block.type === 'gloss_see'" class="ml-4 mb-1 text-sm muted-text italic">
        See: <a v-if="block.attrs?.otherterm" :href="`#${block.attrs.otherterm}`" class="ebook-link-color">{{ extractText(block) }}</a>
        <template v-else>{{ extractText(block) }}</template>
      </dd>

      <!-- GlossSeeAlso -->
      <dd v-else-if="block.type === 'gloss_see_also'" class="ml-4 mb-1 text-sm muted-text italic">
        See also: <a v-if="block.attrs?.otherterm" :href="`#${block.attrs.otherterm}`" class="ebook-link-color">{{ extractText(block) }}</a>
        <template v-else>{{ extractText(block) }}</template>
      </dd>

      <!-- BiblioEntry -->
      <div v-else-if="block.type === 'biblio_entry'" :id="block.attrs?.xml_id" class="biblio-entry mb-3 pl-6 -indent-6">
        <template v-for="(child, ci) in block.content" :key="ci">
          <TextRenderer v-if="child.type === 'text'" :node="child" />
        </template>
      </div>

      <!-- Index Div -->
      <div v-else-if="block.type === 'index_div'" class="mb-3">
        <h3 v-if="block.attrs?.title" class="text-lg font-bold heading-text mb-2">{{ block.attrs.title }}</h3>
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- Index Entry -->
      <div v-else-if="block.type === 'index_entry'" class="mb-1 pl-4 ebook-text">
        <template v-for="(child, ci) in block.content" :key="ci">
          <TextRenderer v-if="child.type === 'text'" :node="child" />
        </template>
      </div>

      <!-- Step -->
      <li v-else-if="block.type === 'step'" :id="block.attrs?.xml_id" class="step-item mb-3">
        <div class="step-content">
          <MirrorRenderer :blocks="block.content || []" />
        </div>
      </li>

      <!-- SubSteps -->
      <li v-else-if="block.type === 'substeps'" class="substeps-item">
        <ol class="procedure-list ml-4">
          <MirrorRenderer :blocks="block.content || []" />
        </ol>
      </li>

      <!-- Equation -->
      <div v-else-if="block.type === 'equation'" :id="block.attrs?.xml_id" class="equation-block my-6 text-center">
        <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-2">
          <span v-if="getNumbering(block.attrs?.xml_id)">Equation {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
        </div>
        <div class="equation-content">
          <MirrorRenderer :blocks="block.content || []" />
        </div>
      </div>

      <!-- CalloutList -->
      <div v-else-if="block.type === 'calloutlist'" :id="block.attrs?.xml_id" class="mb-4">
        <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-2">{{ block.attrs.title }}</div>
        <ol class="callout-list">
          <MirrorRenderer :blocks="block.content || []" />
        </ol>
      </div>

      <!-- Callout -->
      <li v-else-if="block.type === 'callout'" :id="block.attrs?.xml_id" class="callout-item mb-2">
        <MirrorRenderer :blocks="block.content || []" />
      </li>

      <!-- QandA Set -->
      <section v-else-if="block.type === 'qandaset'" :id="block.attrs?.xml_id" class="qandaset-block mb-6">
        <h3 v-if="block.attrs?.title" class="text-lg font-semibold heading-text mb-3">{{ block.attrs.title }}</h3>
        <div class="qandaset-entries">
          <MirrorRenderer :blocks="block.content || []" />
        </div>
      </section>

      <!-- QandA Entry -->
      <div v-else-if="block.type === 'qandaentry'" :id="block.attrs?.xml_id" class="qanda-entry mb-4">
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- Question -->
      <div v-else-if="block.type === 'question'" class="question-block">
        <div class="question-label">Q:</div>
        <div class="question-content">
          <MirrorRenderer :blocks="block.content || []" />
        </div>
      </div>

      <!-- Answer -->
      <div v-else-if="block.type === 'answer'" class="answer-block">
        <div class="answer-label">A:</div>
        <div class="answer-content">
          <MirrorRenderer :blocks="block.content || []" />
        </div>
      </div>

      <!-- Sidebar -->
      <aside v-else-if="block.type === 'sidebar'" :id="block.attrs?.xml_id" class="sidebar-block my-4">
        <div v-if="block.attrs?.title" class="sidebar-title">{{ block.attrs.title }}</div>
        <MirrorRenderer :blocks="block.content || []" />
      </aside>

      <!-- Synopsis -->
      <div v-else-if="block.type === 'synopsis'" class="mb-4 p-3 bg-ebook-bg-secondary rounded text-sm font-mono">
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- Paragraph with inline content -->
      <p v-else-if="block.type === 'paragraph'" :id="block.attrs?.xml_id"
         :class="[
           block.attrs?.class === 'refmeta-synopsis'
             ? 'mb-2 px-3 py-2 bg-ebook-bg-secondary rounded border border-ebook-border font-mono text-sm'
             : block.attrs?.class === 'refpurpose'
             ? 'mb-1 ebook-text leading-relaxed italic muted-text'
             : block.attrs?.class === 'refclass'
             ? 'mb-3 text-xs font-mono px-2 py-0.5 rounded inline-block refclass-badge'
             : 'mb-3 ebook-text leading-relaxed'
         ]">
        <template v-for="(child, ci) in block.content" :key="ci">
          <TextRenderer v-if="child.type === 'text'" :node="child" />
          <sup v-else-if="child.type === 'footnote_marker'" class="footnote-marker">
            <a :href="`#${child.attrs?.id}`" :id="child.attrs?.ref_id">{{ child.attrs?.number }}</a>
          </sup>
        </template>
      </p>

      <!-- Code block with syntax highlighting -->
      <div v-else-if="block.type === 'code_block'" :id="block.attrs?.xml_id" class="mb-4">
        <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-1">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="mr-1">Example {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
        </div>
        <div v-else-if="getNumbering(block.attrs?.xml_id)" class="text-sm font-semibold muted-text mb-1">
          Example {{ getNumbering(block.attrs?.xml_id) }}
        </div>
        <div class="code-block-wrapper relative group">
          <span v-if="block.attrs?.language" class="code-language-badge">{{ block.attrs.language }}</span>
          <pre class="code-block overflow-x-auto text-sm font-mono" :class="[block.attrs?.language ? 'language-' + block.attrs.language : '', block.attrs?.callouts ? 'has-callouts' : '']"><code v-html="highlightWithCallouts(extractText(block), block.attrs?.language, block.attrs?.callouts)"></code></pre>
          <button
            class="copy-btn"
            :class="{ 'copy-btn-done': copiedBlockId === getBlockId(block) }"
            @click="copyCode(block, $event)"
            title="Copy code"
          >
            <svg v-if="copiedBlockId !== getBlockId(block)" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
            <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
          </button>
        </div>
      </div>

      <!-- Blockquote -->
      <blockquote v-else-if="block.type === 'blockquote'" class="border-l-4 border-blue-500 pl-4 py-1 my-4 bg-ebook-bg-secondary rounded-r-lg">
        <MirrorRenderer :blocks="block.content || []" />
      </blockquote>

      <!-- Ordered List -->
      <ol v-else-if="block.type === 'ordered_list'" class="list-decimal ml-6 mb-3 space-y-1">
        <li v-for="(item, li) in block.content" :key="li" class="ebook-text">
          <template v-if="item.type === 'list_item'">
            <MirrorRenderer :blocks="item.content || []" />
          </template>
        </li>
      </ol>

      <!-- Bullet List -->
      <ul v-else-if="block.type === 'bullet_list'" class="list-disc ml-6 mb-3 space-y-1">
        <li v-for="(item, li) in block.content" :key="li" class="ebook-text">
          <template v-if="item.type === 'list_item'">
            <MirrorRenderer :blocks="item.content || []" />
          </template>
        </li>
      </ul>

      <!-- Definition List -->
      <dl v-else-if="block.type === 'dl'" class="mb-4 ml-4">
        <template v-for="(item, di) in block.content" :key="di">
          <template v-if="item.type === 'definition_term'">
            <dt class="font-semibold ebook-text mt-2">
              <MirrorRenderer :blocks="item.content || []" />
            </dt>
          </template>
          <template v-if="item.type === 'definition_description'">
            <dd class="ml-4 muted-text mb-2">
              <MirrorRenderer :blocks="item.content || []" />
            </dd>
          </template>
        </template>
      </dl>

      <!-- Image -->
      <figure v-else-if="block.type === 'image'" :id="block.attrs?.xml_id" class="my-6 overflow-hidden rounded-lg cursor-zoom-in" @click="lightboxOpen(block.attrs?.src || '', block.attrs?.alt, block.attrs?.title)">
        <img :src="block.attrs?.src" :alt="block.attrs?.alt || ''" class="max-w-full h-auto rounded shadow" loading="lazy">
        <figcaption class="mt-2 text-sm muted-text text-center italic">
          <span v-if="getNumbering(block.attrs?.xml_id)">Figure {{ getNumbering(block.attrs?.xml_id) }}<span v-if="block.attrs?.title">: </span></span>{{ block.attrs?.title }}
        </figcaption>
      </figure>

      <!-- Admonition -->
      <div v-else-if="block.type === 'admonition'" :class="getAdmonitionClass(block.attrs?.admonition_type)" class="admonition">
        <div class="admonition-icon" v-html="getAdmonitionIconSvg(block.attrs?.admonition_type)"></div>
        <div class="admonition-content">
          <div class="admonition-title">{{ getAdmonitionTitle(block.attrs?.admonition_type) }}</div>
          <MirrorRenderer :blocks="block.content || []" />
        </div>
      </div>

      <!-- Table -->
      <div v-else-if="block.type === 'table'" :id="block.attrs?.xml_id" class="mb-4">
        <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-1">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="mr-1">Table {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
        </div>
        <div class="table-scroll-wrapper">
          <table class="w-full border-collapse text-sm">
            <thead v-for="(section, si) in (block.content || []).filter(s => s.type === 'table_head')" :key="'h'+si">
              <tr v-for="(row, ri) in section.content" :key="ri" class="border-b-2 border-ebook-border">
                <th v-for="(cell, ci) in row.content" :key="ci"
                    class="px-3 py-2 text-left font-semibold ebook-text border border-ebook-border"
                    :colspan="cell.attrs?.nameend ? getColSpan(cell.attrs) : undefined"
                    :rowspan="cell.attrs?.morerows ? parseInt(cell.attrs.morerows) + 1 : undefined">
                  <template v-for="(child, i) in cell.content" :key="i">
                    <TextRenderer v-if="child.type === 'text'" :node="child" />
                  </template>
                </th>
              </tr>
            </thead>
            <tbody v-for="(section, si) in (block.content || []).filter(s => s.type === 'table_body')" :key="'b'+si">
              <tr v-for="(row, ri) in section.content" :key="ri" class="table-row border-b border-ebook-border">
                <td v-for="(cell, ci) in row.content" :key="ci"
                    class="px-3 py-2 ebook-text border border-ebook-border"
                    :colspan="cell.attrs?.nameend ? getColSpan(cell.attrs) : undefined"
                    :rowspan="cell.attrs?.morerows ? parseInt(cell.attrs.morerows) + 1 : undefined">
                  <template v-for="(child, i) in cell.content" :key="i">
                    <TextRenderer v-if="child.type === 'text'" :node="child" />
                  </template>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Footnotes collection -->
      <div v-else-if="block.type === 'footnotes'" class="footnotes mt-8 pt-4 border-t border-ebook-border">
        <ol class="pl-5 list-decimal">
          <li v-for="fn in block.content" :key="fn.attrs?.id" :id="fn.attrs?.id" class="mb-2 text-sm ebook-text">
            <MirrorRenderer :blocks="fn.content || []" />
            <a :href="`#${fn.attrs?.ref_id}`" class="footnote-backref ml-1">&#8617;</a>
          </li>
        </ol>
      </div>

      <!-- Soft break -->
      <br v-else-if="block.type === 'soft_break'" />

      <!-- Annotation with popup -->
      <div v-else-if="block.type === 'annotation'" class="annotation-inline">
        <span
          class="annotation-marker"
          @mouseenter="showAnnotation(index, $event)"
          @mouseleave="scheduleHideAnnotation(index)"
          @click="toggleAnnotation(index, $event)"
        >
          <svg class="annotation-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        </span>
        <AnnotationPopup
          :visible="activeAnnotation === index"
          :targetRect="annotationTargetRect"
          @mouseenter="cancelHideAnnotation"
          @mouseleave="scheduleHideAnnotation(index)"
        >
          <MirrorRenderer :blocks="block.content || []" />
        </AnnotationPopup>
      </div>

      <!-- Fallback: render as paragraph if text exists -->
      <p v-else-if="extractText(block)" class="mb-3 ebook-text">
        {{ extractText(block) }}
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, inject } from 'vue'
import TextRenderer from './TextRenderer.vue'
import AnnotationPopup from './AnnotationPopup.vue'
import SectionBlock from './blocks/SectionBlock.vue'
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'
import { highlightCode } from '@/utils/highlight'
import { copyToClipboard } from '@/utils/clipboard'
import { extractText } from '@/utils/nodeExtract'
import { isSectionType } from '@/utils/typeMetadata'

defineProps<{
  blocks: MirrorBlockNode[]
}>()

const documentStore = useDocumentStore()

const copiedBlockId = ref<string | null>(null)
const activeAnnotation = ref<number | null>(null)
const annotationTargetRect = ref<DOMRect | null>(null)
let annotationHideTimer: ReturnType<typeof setTimeout> | null = null

function showAnnotation(index: number, event: MouseEvent) {
  const target = event.currentTarget as HTMLElement
  annotationTargetRect.value = target.getBoundingClientRect()
  activeAnnotation.value = index
  cancelHideAnnotation()
}

function scheduleHideAnnotation(index: number) {
  annotationHideTimer = setTimeout(() => {
    if (activeAnnotation.value === index) {
      activeAnnotation.value = null
    }
  }, 200)
}

function cancelHideAnnotation() {
  if (annotationHideTimer) {
    clearTimeout(annotationHideTimer)
    annotationHideTimer = null
  }
}

function toggleAnnotation(index: number, event: MouseEvent) {
  if (activeAnnotation.value === index) {
    activeAnnotation.value = null
  } else {
    showAnnotation(index, event)
  }
}

type LightboxOpener = (src: string, alt?: string, title?: string) => void
const lightboxOpen = inject<LightboxOpener>('lightbox', () => {})

function getBlockId(block: MirrorBlockNode): string {
  return `${block.type}-${extractText(block).slice(0, 40)}`
}

function copyCode(block: MirrorBlockNode, event: Event) {
  const btn = event.currentTarget as HTMLElement
  const wrapper = btn.closest('.code-block-wrapper')
  const codeEl = wrapper?.querySelector('code')
  const text = codeEl?.textContent || extractText(block)

  const id = getBlockId(block)
  copyToClipboard(text)

  copiedBlockId.value = id
  setTimeout(() => {
    if (copiedBlockId.value === id) {
      copiedBlockId.value = null
    }
  }, 2000)
}

function getNumbering(id: string | undefined): string {
  if (!id) return ''
  return documentStore.getNumbering(id)
}

interface CalloutMarker {
  number: number
  id?: string
  label: string
}

function highlightWithCallouts(code: string, language: string | undefined, callouts?: CalloutMarker[]): string {
  let html = highlightCode(code, language)
  if (callouts && callouts.length > 0) {
    for (const co of callouts) {
      const label = co.label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      const pattern = `\\(${label}\\)`
      const regex = new RegExp(pattern)
      const id = co.id ? ` id="${co.id}"` : ''
      html = html.replace(regex, `<span class="callout-badge"${id}>${co.label}</span>`)
    }
  }
  return html
}

function getColSpan(attrs: Record<string, string | undefined> | undefined): number | undefined {
  if (!attrs?.namest || !attrs?.nameend) return undefined
  const cols = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const start = cols.indexOf(attrs.namest.toUpperCase())
  const end = cols.indexOf(attrs.nameend.toUpperCase())
  return start >= 0 && end >= 0 ? end - start + 1 : undefined
}

function getAdmonitionClass(type: string | undefined): string {
  switch (type) {
    case 'note': return 'admonition-note'
    case 'warning': return 'admonition-warning'
    case 'danger': return 'admonition-danger'
    case 'caution': return 'admonition-caution'
    case 'important': return 'admonition-important'
    case 'tip': return 'admonition-tip'
    default: return 'admonition-note'
  }
}

function getAdmonitionIconSvg(type: string | undefined): string {
  const s = 'width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'
  switch (type) {
    case 'note':
      return `<svg ${s}><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>`
    case 'warning':
      return `<svg ${s}><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`
    case 'danger':
      return `<svg ${s}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`
    case 'caution':
      return `<svg ${s}><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`
    case 'important':
      return `<svg ${s}><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>`
    case 'tip':
      return `<svg ${s}><path d="M9 18h6"/><path d="M10 22h4"/><path d="M12 2a7 7 0 00-4 12.7V17h8v-2.3A7 7 0 0012 2z"/></svg>`
    default:
      return `<svg ${s}><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>`
  }
}

function getAdmonitionTitle(type: string | undefined): string {
  switch (type) {
    case 'note': return 'Note'
    case 'warning': return 'Warning'
    case 'danger': return 'Danger'
    case 'caution': return 'Caution'
    case 'important': return 'Important'
    case 'tip': return 'Tip'
    default: return 'Note'
  }
}
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.heading-text { color: var(--ebook-text-heading); }
.muted-text { color: var(--ebook-text-muted); }
.bg-ebook-bg-secondary { background: var(--ebook-bg-secondary); }
.border-ebook-border { border-color: var(--ebook-border); }

/* Admonition layout */
.admonition {
  display: flex;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 8px;
  margin: 16px 0;
}
.admonition-icon { flex-shrink: 0; width: 20px; height: 20px; margin-top: 1px; }
.admonition-icon :deep(svg) { width: 20px; height: 20px; }
.admonition-title { font-weight: 700; margin-bottom: 4px; text-transform: uppercase; font-size: 0.75em; letter-spacing: 0.04em; }
.admonition-content { flex: 1; min-width: 0; }

/* Admonition colors */
.admonition-note { background: color-mix(in srgb, #3b82f6 10%, var(--ebook-bg)); color: #1d4ed8; border-left: 3px solid #3b82f6; }
.admonition-warning { background: color-mix(in srgb, #eab308 10%, var(--ebook-bg)); color: #a16207; border-left: 3px solid #eab308; }
.admonition-danger { background: color-mix(in srgb, #ef4444 10%, var(--ebook-bg)); color: #b91c1c; border-left: 3px solid #ef4444; }
.admonition-caution { background: color-mix(in srgb, #f97316 10%, var(--ebook-bg)); color: #c2410c; border-left: 3px solid #f97316; }
.admonition-important { background: color-mix(in srgb, #a855f7 10%, var(--ebook-bg)); color: #7e22ce; border-left: 3px solid #a855f7; }
.admonition-tip { background: color-mix(in srgb, #22c55e 10%, var(--ebook-bg)); color: #15803d; border-left: 3px solid #22c55e; }

/* Code block */
.code-block-wrapper { position: relative; border-radius: 8px; overflow: hidden; }
.code-block {
  background: var(--ebook-code-bg); color: var(--ebook-code-text);
  border-left: 3px solid var(--ebook-accent);
  padding: 16px 16px 16px 19px; overflow-x: auto;
  font-family: 'JetBrains Mono', 'Fira Code', 'SF Mono', 'Menlo', 'Consolas', monospace;
  line-height: 1.5;
}
.code-block code { font-family: inherit; background: none; padding: 0; }
.code-language-badge {
  position: absolute; top: 6px; right: 44px;
  font-size: 0.6rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em;
  font-family: system-ui, -apple-system, sans-serif;
  color: var(--chrome-text-dim); background: var(--chrome-bg);
  padding: 2px 8px; border-radius: 4px; border: 1px solid var(--chrome-border);
  z-index: 1; opacity: 0; transition: opacity 0.15s ease;
}
.code-block-wrapper:hover .code-language-badge { opacity: 1; }
.copy-btn {
  position: absolute; top: 8px; right: 8px;
  display: flex; align-items: center; justify-content: center;
  width: 32px; height: 32px; padding: 4px; border-radius: 6px;
  background: var(--chrome-bg); color: var(--chrome-text-dim);
  border: 1px solid var(--chrome-border);
  opacity: 0; transition: opacity 0.15s ease, background 0.15s ease; cursor: pointer;
}
.code-block-wrapper:hover .copy-btn, .copy-btn:focus, .copy-btn-done { opacity: 1; }
.copy-btn:hover { background: var(--chrome-bg-hover); color: var(--chrome-text); }
.copy-btn-done { background: color-mix(in srgb, #22c55e 15%, var(--chrome-bg)); color: #22c55e; border-color: #22c55e; }
.refclass-badge { background: var(--chrome-bg-hover); color: var(--chrome-text-dim); }

/* Footnotes */
.footnote-marker { font-size: 0.75em; vertical-align: super; line-height: 0; }
.footnote-marker a { color: var(--ebook-link-color); text-decoration: none; cursor: pointer; }
.footnote-marker a:hover { text-decoration: underline; }
.footnote-backref { color: var(--ebook-link-color); text-decoration: none; font-size: 0.8em; }
.footnote-backref:hover { text-decoration: underline; }

/* Annotation */
.annotation-inline { display: inline; }
.annotation-marker {
  display: inline-flex; align-items: center; justify-content: center;
  width: 20px; height: 20px; border-radius: 50%;
  background: color-mix(in srgb, var(--ebook-link-color) 12%, var(--ebook-bg));
  color: var(--ebook-link-color); cursor: pointer; vertical-align: super;
  margin: 0 2px; transition: background 0.15s ease;
}
.annotation-marker:hover { background: color-mix(in srgb, var(--ebook-link-color) 25%, var(--ebook-bg)); }
.annotation-icon { width: 12px; height: 12px; }

/* Table */
.table-scroll-wrapper { overflow-x: auto; -webkit-overflow-scrolling: touch; border-radius: 6px; border: 1px solid var(--ebook-border); }
.table-scroll-wrapper table { min-width: 400px; }
.table-scroll-wrapper thead th { position: sticky; top: 0; background: var(--ebook-bg-secondary); z-index: 1; }
.table-row:nth-child(even) { background: color-mix(in srgb, var(--ebook-text) 3%, var(--ebook-bg)); }

/* Procedure */
.procedure-list { list-style: decimal; padding-left: 1.5rem; counter-reset: procedure-counter; }
.step-item { margin-bottom: 0.75rem; padding-left: 0.5rem; }
.step-content { margin-top: 0.25rem; }
.substeps-item { list-style: none; }
.substeps-item .procedure-list { margin-top: 0.5rem; }

/* Callout */
.callout-list { list-style: decimal; padding-left: 1.5rem; }
.callout-item { margin-bottom: 0.5rem; font-size: 0.95em; }
.callout-badge {
  display: inline-flex; align-items: center; justify-content: center;
  min-width: 1.4em; height: 1.4em; font-size: 0.75em;
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 600; line-height: 1; color: #fff;
  background: var(--ebook-link-color); border-radius: 50%;
  vertical-align: baseline; padding: 0 0.2em; margin: 0 1px;
}
.has-callouts :deep(.callout-badge) { cursor: default; }

/* Sidebar */
.sidebar-block { padding: 1rem 1.25rem; border-left: 3px solid var(--ebook-accent); background: color-mix(in srgb, var(--ebook-accent) 5%, var(--ebook-bg)); border-radius: 0 8px 8px 0; }
.sidebar-title { font-weight: 600; font-size: 0.9em; text-transform: uppercase; letter-spacing: 0.04em; color: var(--ebook-accent); margin-bottom: 0.5rem; }

/* Equation */
.equation-block { padding: 1rem; background: var(--ebook-bg-secondary); border-radius: 8px; border: 1px solid var(--ebook-border); }
.equation-content { font-size: 1.1em; }

/* QandA */
.qandaset-block { border-left: 3px solid var(--ebook-accent); padding-left: 1rem; }
.qandaset-entries { display: flex; flex-direction: column; gap: 0.75rem; }
.qanda-entry { padding: 0.75rem 1rem; background: var(--ebook-bg-secondary); border-radius: 8px; border: 1px solid var(--ebook-border); }
.question-block, .answer-block { display: flex; gap: 0.5rem; align-items: flex-start; }
.question-label { font-weight: 700; color: var(--ebook-accent); flex-shrink: 0; font-size: 0.95em; }
.answer-label { font-weight: 700; color: var(--ebook-text-muted); flex-shrink: 0; font-size: 0.95em; }
.question-content, .answer-content { flex: 1; min-width: 0; }
.answer-block { margin-top: 0.25rem; padding-left: 0.5rem; border-left: 2px solid var(--ebook-border); }

/* Link color */
.ebook-link-color { color: var(--ebook-link-color); }
.ebook-link-color:hover { text-decoration: underline; }

/* Bibliography */
.biblio-entry { hanging-punctuation: first; }
</style>
