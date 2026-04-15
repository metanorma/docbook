<template>
  <div class="content-blocks">
    <template v-for="(block, index) in blocks" :key="index">
      <!-- Reference Entry (dictionary-style entry) -->
      <ReferenceEntry v-if="block.type === 'reference_entry'" :block="block" />
      <p v-if="block.type === 'paragraph'" class="content-text mb-3 leading-relaxed">
        <template v-if="block.children && block.children.length > 0">
          <template v-for="(child, ci) in block.children" :key="ci">
            <strong v-if="child.type === 'strong'" class="font-bold content-text-strong">{{ child.text }}</strong>
            <em v-else-if="child.type === 'italic'" class="italic content-text-muted">{{ child.text }}</em>
            <em v-else-if="child.type === 'emphasis'" class="italic content-text-muted">{{ child.text }}</em>
            <code v-else-if="child.type === 'codetext'" class="content-inline-code px-1.5 py-0.5 rounded text-sm font-mono">{{ child.text }}</code>
            <a v-else-if="child.type === 'link'" :href="child.src" class="content-link hover:underline">{{ child.text }}</a>
            <a v-else-if="child.type === 'biblioref'" :href="child.src" class="content-biblioref hover:underline italic">{{ child.text }}</a>
            <span v-else-if="child.type === 'citation'" class="content-citation italic">{{ child.text }}</span>
            <a v-else-if="child.type === 'citation_link'" :href="child.src" class="content-citation hover:underline italic">{{ child.text }}</a>
            <a v-else-if="child.type === 'xref'" :href="child.src" class="content-link hover:underline content-xref-border">{{ child.text }}</a>
            <img v-else-if="child.type === 'inline_image'" :src="child.src" :alt="child.alt || ''" class="max-w-full h-auto rounded inline">
            <span v-else-if="child.type === 'text'" v-html="escapeHtml(child.text || '')"></span>
          </template>
        </template>
        <template v-else>
          <span v-html="escapeHtml(block.text || '')"></span>
        </template>
      </p>

      <!-- Code block -->
      <pre v-else-if="block.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :class="block.language ? 'language-' + block.language : ''"><code :class="block.language ? 'language-' + block.language : ''" v-html="highlightCode(block.text || '', block.language)"></code></pre>

      <!-- Image -->
      <figure v-else-if="block.type === 'image'" class="my-6 overflow-hidden rounded-lg">
        <img :src="block.src" :alt="block.alt || ''" class="max-w-full h-auto rounded shadow" loading="lazy">
        <figcaption v-if="block.title" class="content-text-muted mt-2 text-sm text-center italic">{{ block.title }}</figcaption>
      </figure>

      <!-- Blockquote -->
      <blockquote v-else-if="block.type === 'blockquote'" class="content-blockquote border-l-4 border-blue-500 pl-4 py-1 my-4 rounded-r-lg">
        <p v-for="(child, ci) in block.children" :key="ci" class="content-text mb-3">
          <template v-if="child.type === 'paragraph'">{{ child.text }}</template>
        </p>
        <footer v-if="block.text" class="content-text-muted text-sm mt-2">&mdash; {{ block.text }}</footer>
      </blockquote>

      <!-- Ordered List -->
      <ol v-else-if="block.type === 'ordered_list'" class="list-decimal ml-6 mb-3 space-y-1">
        <li v-for="(item, li) in block.children" :key="li" class="content-text">
          <template v-if="item.type === 'list_item'">
            <template v-for="(child, ci) in item.children" :key="ci">
              <p v-if="child.type === 'paragraph'" class="mb-3">
                <template v-for="(para, pi) in (child.children || [])" :key="pi">
                  <strong v-if="para.type === 'strong'">{{ para.text }}</strong>
                  <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
                  <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
                  <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1.5 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
                  <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
                  <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
                  <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
                  <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
                </template>
              </p>
            </template>
          </template>
        </li>
      </ol>

      <!-- Itemized List -->
      <ul v-else-if="block.type === 'itemized_list'" class="list-disc ml-6 mb-3 space-y-1">
        <li v-for="(item, li) in block.children" :key="li" class="content-text">
          <template v-if="item.type === 'list_item'">
            <template v-for="(child, ci) in item.children" :key="ci">
              <p v-if="child.type === 'paragraph'" class="mb-3">
                <template v-for="(para, pi) in (child.children || [])" :key="pi">
                  <strong v-if="para.type === 'strong'">{{ para.text }}</strong>
                  <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
                  <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
                  <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1.5 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
                  <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
                  <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
                  <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
                  <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
                </template>
              </p>
            </template>
          </template>
        </li>
      </ul>

      <!-- Definition List (glossary) -->
      <dl v-else-if="block.type === 'definition_list'" class="mb-4 ml-4">
        <template v-for="(item, di) in block.children" :key="di">
          <template v-if="item.type === 'definition_term'">
            <template v-for="(child, ci) in (item.children || [])" :key="ci">
              <dt v-if="child.type === 'text'" class="font-semibold content-text mt-2">{{ child.text }}</dt>
              <dt v-else-if="child.type === 'codetext'" class="font-mono content-code-text mt-2">{{ child.text }}</dt>
            </template>
          </template>
          <template v-if="item.type === 'definition_description'">
            <template v-for="(child, ci) in (item.children || [])" :key="ci">
              <dd v-if="child.type === 'paragraph'" class="content-text-muted ml-4 mb-2">
                <template v-for="(para, pi) in (child.children || [])" :key="pi">
                  <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
                  <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
                  <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
                  <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
                  <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
                  <a v-else-if="para.type === 'biblioref'" :href="para.src" class="content-biblioref hover:underline italic">{{ para.text }}</a>
                  <span v-else-if="para.type === 'citation'" class="content-citation italic">{{ para.text }}</span>
                  <a v-else-if="para.type === 'citation_link'" :href="para.src" class="content-citation hover:underline italic">{{ para.text }}</a>
                  <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
                  <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
                  <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
                </template>
              </dd>
            </template>
          </template>
        </template>
      </dl>

      <!-- Admonitions -->
      <div v-else-if="block.type === 'note'" class="admonition admonition-note border-l-4 border-blue-500 rounded-r-lg p-4 my-4">
        <div class="font-bold mb-1" style="color: #2563eb">{{ block.text || 'Note' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="content-text mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'warning'" class="admonition admonition-warning border-l-4 border-yellow-500 rounded-r-lg p-4 my-4">
        <div class="font-bold mb-1" style="color: #ca8a04">{{ block.text || 'Warning' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="content-text mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'danger'" class="admonition admonition-danger border-l-4 border-red-500 rounded-r-lg p-4 my-4">
        <div class="font-bold mb-1" style="color: #dc2626">{{ block.text || 'Danger' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="content-text mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'caution'" class="admonition admonition-caution border-l-4 border-orange-500 rounded-r-lg p-4 my-4">
        <div class="font-bold mb-1" style="color: #ea580c">{{ block.text || 'Caution' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="content-text mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'important'" class="admonition admonition-important border-l-4 border-purple-500 rounded-r-lg p-4 my-4">
        <div class="font-bold mb-1" style="color: #9333ea">{{ block.text || 'Important' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="content-text mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'tip'" class="admonition admonition-tip border-l-4 border-green-500 rounded-r-lg p-4 my-4">
        <div class="font-bold mb-1" style="color: #16a34a">{{ block.text || 'Tip' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="content-text mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="content-inline-code px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="content-link hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="content-link hover:underline content-xref-border">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="content-code-block rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <!-- Bibliography entry (reference) -->
      <div v-else-if="block.type === 'bibliography_entry'" class="biblio-entry mb-4 ml-4 pl-4 border-l-2">
        <p class="content-text">
          <template v-for="(child, ci) in (block.children || [])" :key="ci">
            <span v-if="child.type === 'text'">{{ child.text }}</span>
            <span v-else-if="child.type === 'biblio_abbrev'" :class="child.className">{{ child.text }}</span>
            <cite v-else-if="child.type === 'biblio_citetitle'" :class="child.className">{{ child.text }}</cite>
            <span v-else-if="child.type === 'biblio_author' || child.type === 'biblio_personname' || child.type === 'biblio_firstname' || child.type === 'biblio_surname'" :class="child.className">{{ child.text }}</span>
            <span v-else-if="child.type === 'biblio_orgname' || child.type === 'biblio_publishername' || child.type === 'biblio_pubdate' || child.type === 'biblio_bibliosource'" :class="child.className">{{ child.text }}</span>
            <a v-else-if="child.type === 'link'" :href="child.src" :class="child.className" class="content-link hover:underline">{{ child.text }}</a>
            <a v-else-if="child.type === 'xref'" :href="child.src" class="content-link hover:underline content-xref-border">{{ child.text }}</a>
            <span v-if="ci < (block.children?.length || 0) - 1" :key="'space-' + ci"> </span>
          </template>
        </p>
      </div>

      <!-- Reference entry (refentry - dictionary-style entry) -->
      <!-- Handled by ReferenceEntry component above -->

      <!-- Description section (from refsection content) -->
      <div v-else-if="block.type === 'description_section'" class="description-section mb-4">
        <BlockRenderer :blocks="block.children || []" />
      </div>

      <!-- Example output (informalexample - styled differently from code) -->
      <div v-else-if="block.type === 'example_output'" class="example-output border-2 border-dashed border-green-500 rounded-lg p-4 my-4">
        <span class="example-output-label text-xs font-semibold uppercase tracking-wide block mb-2">Example:</span>
        <BlockRenderer :blocks="block.children || []" />
      </div>

      <!-- Index section (whole index) -->
      <div v-else-if="block.type === 'index_section'" class="mb-8">
        <h2 v-if="block.text" class="content-text-heading text-2xl font-bold mb-6">{{ block.text }}</h2>
        <div class="index-columns">
          <BlockRenderer :blocks="block.children || []" />
        </div>
      </div>

      <!-- Index letter group -->
      <div v-else-if="block.type === 'index_letter'" class="index-letter-section mb-6">
        <h3 class="index-letter content-text-muted text-xl font-bold mb-3 border-b pb-1">{{ block.text }}</h3>
        <ul class="index-entries space-y-1">
          <BlockRenderer :blocks="block.children || []" />
        </ul>
      </div>

      <!-- Index entry -->
      <li v-else-if="block.type === 'index_entry'" class="index-entry ml-4">
        <span class="content-text">{{ block.text }}</span>
        <template v-for="(child, ci) in block.children" :key="ci">
          <a v-if="child.type === 'index_reference'" :href="child.src" class="index-section-link content-link ml-2 hover:underline text-sm">{{ child.text }}</a>
          <span v-else-if="child.type === 'index_see'" class="index-see content-text-muted ml-2 italic text-sm">{{ child.text }}</span>
          <span v-else-if="child.type === 'index_see_also'" class="index-see-also content-text-muted ml-2 italic text-sm">{{ child.text }}</span>
        </template>
      </li>

      <!-- Nested section blocks -->
      <div v-else-if="block.type === 'section'" class="mb-6">
        <BlockRenderer :blocks="block.children || []" />
      </div>

      <!-- Heading (used for simplesect titles within content) -->
      <h3 v-else-if="block.type === 'heading'" class="content-text-heading text-lg font-semibold mb-2 mt-4">
        {{ block.text }}
      </h3>

      <!-- Reference meta (refentrytitle, refmiscinfo - metadata) -->
      <span v-else-if="block.type === 'reference_meta'" class="reference-meta content-text-dim text-xs block mb-1">
        {{ block.text }}
      </span>

      <!-- Reference class (refclass badge) -->
      <span v-else-if="block.type === 'reference_class'" class="reference-badge reference-class-badge inline-block px-2 py-0.5 text-xs rounded-full">
        {{ block.text }}
      </span>

      <!-- Reference badge (new type for refclass - e.g., "pi") -->
      <span v-else-if="block.type === 'reference_badge'" class="reference-badge reference-generic-badge inline-block text-[0.65rem] font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full">
        {{ block.text }}
      </span>

      <!-- Reference name (refname - headword) -->
      <h2 v-else-if="block.type === 'reference_name'" class="reference-name reference-name-text text-2xl font-bold font-mono mb-1">
        {{ block.text }}
      </h2>

      <!-- Reference definition (refpurpose - definition) -->
      <p v-else-if="block.type === 'reference_definition'" class="reference-definition content-text-muted text-base italic mb-4">
        {{ block.text }}
      </p>

      <!-- Fallback: render as paragraph if text exists -->
      <p v-else-if="block.text" class="content-text mb-3" v-html="escapeHtml(block.text)"></p>
    </template>
  </div>
</template>

<script setup lang="ts">
import type { ContentBlock } from '../stores/documentStore'
import ReferenceEntry from './ReferenceEntry.vue'

declare const Prism: any

defineProps<{
  blocks: ContentBlock[]
}>()

function escapeHtml(text: string): string {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

function highlightCode(text: string, language: string | null): string {
  const lang = language || 'plaintext'
  try {
    if (Prism && Prism.languages && Prism.languages[lang]) {
      return Prism.highlight(text, Prism.languages[lang], lang)
    }
  } catch (e) {
    // Fallback to escaped HTML if Prism fails
  }
  return escapeHtml(text)
}
</script>

<style scoped>
/* Text colors */
.content-text {
  color: var(--ebook-text);
}
.content-text-strong {
  color: var(--ebook-text);
}
.content-text-muted {
  color: var(--ebook-text-muted);
}
.content-text-heading {
  color: var(--ebook-text-heading);
}
.content-text-dim {
  color: var(--ebook-text-muted);
  opacity: 0.6;
}

/* Links */
.content-link {
  color: var(--ebook-link-color);
}
.content-xref-border {
  border-bottom: 1px dashed var(--ebook-link-color);
}

/* Biblioref (emerald) */
.content-biblioref {
  color: var(--ebook-accent);
}

/* Citation (teal) */
.content-citation {
  color: #0d9488;
}

/* Inline code */
.content-inline-code {
  background: var(--ebook-inline-code-bg);
  color: var(--ebook-inline-code-text);
  border: 1px solid var(--ebook-inline-code-border);
}
.content-code-text {
  color: var(--ebook-inline-code-text);
}

/* Code block */
.content-code-block {
  background: var(--ebook-inline-code-bg);
  color: var(--ebook-text);
  border: 1px solid var(--ebook-border);
}

/* Blockquote */
.content-blockquote {
  background: var(--ebook-bg-secondary);
}

/* Admonitions */
.admonition-note {
  background: color-mix(in srgb, #3b82f6 10%, var(--ebook-bg));
}
.admonition-warning {
  background: color-mix(in srgb, #eab308 10%, var(--ebook-bg));
}
.admonition-danger {
  background: color-mix(in srgb, #ef4444 10%, var(--ebook-bg));
}
.admonition-caution {
  background: color-mix(in srgb, #f97316 10%, var(--ebook-bg));
}
.admonition-important {
  background: color-mix(in srgb, #a855f7 10%, var(--ebook-bg));
}
.admonition-tip {
  background: color-mix(in srgb, #22c55e 10%, var(--ebook-bg));
}

/* Bibliography entry */
.biblio-entry {
  border-color: var(--ebook-border);
}

/* Index letter */
.index-letter {
  border-color: var(--ebook-border);
}

/* Example output */
.example-output {
  background: color-mix(in srgb, #22c55e 10%, var(--ebook-bg));
}
.example-output-label {
  color: #15803d;
}

/* Reference badges */
.reference-class-badge {
  background: color-mix(in srgb, #a855f7 15%, var(--ebook-bg));
  color: #7e22ce;
}
.reference-generic-badge {
  background: var(--ebook-bg-secondary);
  color: var(--ebook-text-muted);
}

/* Reference name (cyan accent) */
.reference-name-text {
  color: #0e7490;
}
</style>
