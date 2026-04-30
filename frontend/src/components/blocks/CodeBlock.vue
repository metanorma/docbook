<template>
  <div :id="block.attrs?.xml_id" class="mb-4">
    <div v-if="block.attrs?.title" class="text-sm font-semibold muted-text mb-1">
      <span v-if="getNumbering(block.attrs?.xml_id)" class="mr-1">Example {{ getNumbering(block.attrs?.xml_id) }}: </span>{{ block.attrs.title }}
    </div>
    <div v-else-if="getNumbering(block.attrs?.xml_id)" class="text-sm font-semibold muted-text mb-1">
      Example {{ getNumbering(block.attrs?.xml_id) }}
    </div>
    <div class="code-block-wrapper relative group">
      <span v-if="block.attrs?.language" class="code-language-badge">{{ block.attrs.language }}</span>
      <pre class="code-block overflow-x-auto text-sm font-mono" :class="[block.attrs?.language ? 'language-' + block.attrs.language : '', block.attrs?.callouts ? 'has-callouts' : '']"><code v-html="highlightedHtml || escapeHtml(extractText(block))"></code></pre>
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
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'
import { highlightCode, escapeHtml } from '@/utils/highlight'
import { copyToClipboard } from '@/utils/clipboard'
import { extractText } from '@/utils/nodeExtract'

const props = defineProps<{ block: MirrorBlockNode }>()

const documentStore = useDocumentStore()
const copiedBlockId = ref<string | null>(null)
const highlightedHtml = ref('')

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

async function updateHighlight() {
  const code = extractText(props.block)
  const lang = props.block.attrs?.language
  highlightedHtml.value = await highlightCode(code, lang)
  // Apply callout markers
  if (props.block.attrs?.callouts?.length) {
    highlightedHtml.value = applyCallouts(highlightedHtml.value, props.block.attrs.callouts)
  }
}

function applyCallouts(html: string, callouts: Array<{ number: number; id?: string; label: string }>): string {
  for (const co of callouts) {
    const label = co.label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    const pattern = `\\(${label}\\)`
    const regex = new RegExp(pattern, 'g')
    const id = co.id ? ` id="${co.id}"` : ''
    html = html.replace(regex, `<span class="callout-badge"${id}>${co.label}</span>`)
  }
  return html
}

onMounted(updateHighlight)
watch(() => [props.block.attrs?.language, props.block.attrs?.callouts], updateHighlight)
</script>

<style scoped>
.muted-text { color: var(--ebook-text-muted); }
.code-block-wrapper { position: relative; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06); }
.code-block {
  background: var(--ebook-code-bg); color: var(--ebook-code-text);
  border-left: 3px solid var(--ebook-accent);
  padding: 16px 16px 16px 19px; overflow-x: auto;
  font-family: 'JetBrains Mono', 'Fira Code', 'SF Mono', 'Menlo', 'Consolas', monospace;
  line-height: 1.5;
  border-left: 3px solid var(--ebook-accent);
}
.code-block code { font-family: inherit; background: none; padding: 0; }
.code-language-badge {
  position: absolute; top: 6px; right: 44px;
  font-size: 0.6rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em;
  font-family: system-ui, -apple-system, sans-serif;
  color: var(--ebook-accent); background: color-mix(in srgb, var(--ebook-accent) 8%, var(--ebook-code-bg));
  padding: 2px 8px; border-radius: 4px; border: 1px solid color-mix(in srgb, var(--ebook-accent) 20%, var(--ebook-border));
  z-index: 1; opacity: 0.7; transition: opacity 0.15s ease;
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
.callout-badge {
  display: inline-flex; align-items: center; justify-content: center;
  min-width: 1.4em; height: 1.4em; font-size: 0.75em;
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 600; line-height: 1; color: #fff;
  background: var(--ebook-link-color); border-radius: 50%;
  vertical-align: baseline; padding: 0 0.2em; margin: 0 1px;
}
.has-callouts :deep(.callout-badge) { cursor: default; }
</style>
