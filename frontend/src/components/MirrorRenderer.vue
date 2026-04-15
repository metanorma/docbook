<template>
  <div class="content-blocks">
    <template v-for="(block, index) in blocks" :key="index">
      <!-- Document node - recurse into content -->
      <template v-if="block.type === 'doc'">
        <MirrorRenderer :blocks="block.content || []" />
      </template>

      <!-- Section -->
      <section v-else-if="block.type === 'section'" :id="block.attrs?.xml_id" class="mb-6">
        <h2 v-if="block.attrs?.title" class="text-xl font-semibold heading-text mb-3">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="muted-text mr-2 font-normal">{{ getNumbering(block.attrs?.xml_id) }}</span>
          {{ block.attrs.title }}
        </h2>
        <MirrorRenderer :blocks="block.content || []" />
      </section>

      <!-- Chapter -->
      <section v-else-if="block.type === 'chapter'" :id="block.attrs?.xml_id" class="mb-6">
        <h1 v-if="block.attrs?.title" class="text-2xl font-bold heading-text mb-4">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="muted-text text-xl font-normal mr-3">{{ getNumbering(block.attrs?.xml_id) }}</span>
          {{ block.attrs.title }}
        </h1>
        <MirrorRenderer :blocks="block.content || []" />
      </section>

      <!-- Appendix -->
      <section v-else-if="block.type === 'appendix'" :id="block.attrs?.xml_id" class="mb-6">
        <h1 v-if="block.attrs?.title" class="text-2xl font-bold heading-text mb-4">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="muted-text text-xl font-normal mr-3">{{ getNumbering(block.attrs?.xml_id) }}</span>
          {{ block.attrs.title }}
        </h1>
        <MirrorRenderer :blocks="block.content || []" />
      </section>

      <!-- Part -->
      <section v-else-if="block.type === 'part'" :id="block.attrs?.xml_id" class="mb-6">
        <h1 v-if="block.attrs?.title" class="text-3xl font-bold heading-text mb-4">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="muted-text text-2xl font-normal mr-3">{{ getNumbering(block.attrs?.xml_id) }}</span>
          {{ block.attrs.title }}
        </h1>
        <MirrorRenderer :blocks="block.content || []" />
      </section>

      <!-- Reference -->
      <section v-else-if="block.type === 'reference'" :id="block.attrs?.xml_id" class="mb-6">
        <h2 v-if="block.attrs?.title" class="text-2xl font-bold heading-text mb-4">
          {{ block.attrs.title }}
        </h2>
        <MirrorRenderer :blocks="block.content || []" />
      </section>

      <!-- RefEntry -->
      <article v-else-if="block.type === 'refentry'" :id="block.attrs?.xml_id" class="mb-6 border border-ebook-border rounded-lg p-4">
        <div v-if="block.attrs?.title" class="text-lg font-bold font-mono heading-text mb-3">{{ block.attrs.title }}</div>
        <MirrorRenderer :blocks="block.content || []" />
      </article>

      <!-- RefSection -->
      <div v-else-if="block.type === 'refsection'" class="mb-4">
        <h3 v-if="block.attrs?.title" class="text-base font-semibold heading-text mb-2">{{ block.attrs.title }}</h3>
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- Synopsis -->
      <div v-else-if="block.type === 'synopsis'" class="mb-4 p-3 bg-ebook-bg-secondary rounded text-sm font-mono">
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- Paragraph with inline content -->
      <p v-else-if="block.type === 'paragraph'" :id="block.attrs?.xml_id"
         :class="[
           block.attrs?.class === 'refmeta-synopsis'
             ? 'mb-2 px-3 py-2 bg-ebook-bg-secondary rounded border border-ebook-border font-mono text-sm'
             : 'mb-3 ebook-text leading-relaxed'
         ]">
        <template v-for="(child, ci) in block.content" :key="ci">
          <TextRenderer v-if="child.type === 'text'" :node="child" />
        </template>
      </p>

      <!-- Code block with syntax highlighting (also used for examples/figures with code) -->
      <div v-else-if="block.type === 'code_block'" :id="block.attrs?.xml_id" class="mb-4">
        <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-1">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="mr-1">Example {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
        </div>
        <div v-else-if="getNumbering(block.attrs?.xml_id)" class="text-sm font-semibold muted-text mb-1">
          Example {{ getNumbering(block.attrs?.xml_id) }}
        </div>
        <pre class="code-block overflow-x-auto text-sm font-mono" :class="block.attrs?.language ? 'language-' + block.attrs.language : ''"><code v-html="highlightCode(getTextContent(block), block.attrs?.language)"></code></pre>
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
      <figure v-else-if="block.type === 'image'" :id="block.attrs?.xml_id" class="my-6 overflow-hidden rounded-lg">
        <img :src="block.attrs?.src" :alt="block.attrs?.alt || ''" class="max-w-full h-auto rounded shadow" loading="lazy">
        <figcaption class="mt-2 text-sm muted-text text-center italic">
          <span v-if="getNumbering(block.attrs?.xml_id)">Figure {{ getNumbering(block.attrs?.xml_id) }}<span v-if="block.attrs?.title">: </span></span>{{ block.attrs?.title }}
        </figcaption>
      </figure>

      <!-- Admonition -->
      <div v-else-if="block.type === 'admonition'" :class="getAdmonitionClass(block.attrs?.admonition_type)">
        <div class="font-bold mb-1">{{ getAdmonitionTitle(block.attrs?.admonition_type) }}</div>
        <MirrorRenderer :blocks="block.content || []" />
      </div>

      <!-- Table -->
      <div v-else-if="block.type === 'table'" :id="block.attrs?.xml_id" class="mb-4">
        <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-1">
          <span v-if="getNumbering(block.attrs?.xml_id)" class="mr-1">Table {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
        </div>
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
            <tr v-for="(row, ri) in section.content" :key="ri" class="border-b border-ebook-border">
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

      <!-- Soft break -->
      <br v-else-if="block.type === 'soft_break'" />

      <!-- Fallback: render as paragraph if text exists -->
      <p v-else-if="getTextContent(block)" class="mb-3 ebook-text">
        {{ getTextContent(block) }}
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
import TextRenderer from './TextRenderer.vue'
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'
import { highlightCode } from '@/utils/highlight'

defineProps<{
  blocks: MirrorBlockNode[]
}>()

const documentStore = useDocumentStore()

function getNumbering(id: string | undefined): string {
  if (!id) return ''
  return documentStore.getNumbering(id)
}

function getTextContent(node: MirrorBlockNode): string {
  if (!node.content) return ''
  return node.content
    .filter((n): n is { type: 'text'; text: string } => n.type === 'text')
    .map(n => n.text)
    .join('')
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
    case 'note':
      return 'admonition admonition-note border-l-4 border-blue-500 rounded-r-lg p-4 my-4'
    case 'warning':
      return 'admonition admonition-warning border-l-4 border-yellow-500 rounded-r-lg p-4 my-4'
    case 'danger':
      return 'admonition admonition-danger border-l-4 border-red-500 rounded-r-lg p-4 my-4'
    case 'caution':
      return 'admonition admonition-caution border-l-4 border-orange-500 rounded-r-lg p-4 my-4'
    case 'important':
      return 'admonition admonition-important border-l-4 border-purple-500 rounded-r-lg p-4 my-4'
    case 'tip':
      return 'admonition admonition-tip border-l-4 border-green-500 rounded-r-lg p-4 my-4'
    default:
      return 'admonition admonition-note border-l-4 border-blue-500 rounded-r-lg p-4 my-4'
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
.ebook-text {
  color: var(--ebook-text);
}

.heading-text {
  color: var(--ebook-text-heading);
}

.muted-text {
  color: var(--ebook-text-muted);
}

.bg-ebook-bg-secondary {
  background: var(--ebook-bg-secondary);
}

.border-ebook-border {
  border-color: var(--ebook-border);
}

/* Admonition backgrounds using color-mix */
.admonition-note {
  background: color-mix(in srgb, #3b82f6 10%, var(--ebook-bg));
  color: #1d4ed8;
}

.admonition-warning {
  background: color-mix(in srgb, #eab308 10%, var(--ebook-bg));
  color: #a16207;
}

.admonition-danger {
  background: color-mix(in srgb, #ef4444 10%, var(--ebook-bg));
  color: #b91c1c;
}

.admonition-caution {
  background: color-mix(in srgb, #f97316 10%, var(--ebook-bg));
  color: #c2410c;
}

.admonition-important {
  background: color-mix(in srgb, #a855f7 10%, var(--ebook-bg));
  color: #7e22ce;
}

.admonition-tip {
  background: color-mix(in srgb, #22c55e 10%, var(--ebook-bg));
  color: #15803d;
}
</style>
