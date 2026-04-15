<template>
  <template v-for="(mark, index) in node.marks" :key="index">
    <em v-if="mark.type === 'emphasis'" class="italic ebook-text">{{ node.text }}</em>
    <strong v-else-if="mark.type === 'strong'" class="font-bold heading-text">{{ node.text }}</strong>
    <em v-else-if="mark.type === 'italic'" class="italic ebook-text">{{ node.text }}</em>
    <code v-else-if="mark.type === 'code'" :class="getCodeClass(mark)">{{ node.text }}</code>
    <a v-else-if="mark.type === 'link'" :href="mark.attrs?.linkend ? '#' + mark.attrs.linkend : mark.attrs?.href" class="link-text hover:underline">{{ node.text }}</a>
    <a v-else-if="mark.type === 'xref'" :href="`#${mark.attrs?.linkend}`" class="xref link-text hover:underline border-b border-dashed border-link">{{ mark.attrs?.resolved || node.text }}</a>
    <span v-else-if="mark.type === 'citation'" class="citation citation-text italic">{{ node.text }}</span>
    <span v-else-if="mark.type === 'tag'" class="tag">&lt;{{ node.text }}&gt;</span>
  </template>
  <template v-if="!node.marks || node.marks.length === 0">
    <span>{{ node.text }}</span>
  </template>
</template>

<script setup lang="ts">
interface Mark {
  type: string
  attrs?: Record<string, any>
}

interface MirrorTextNode {
  type: 'text'
  text: string
  marks?: Mark[]
}

const props = defineProps<{
  node: MirrorTextNode
}>()

function getCodeClass(mark: Mark): string {
  const role = mark.attrs?.role || 'literal'
  return `code-${role} inline-code px-1.5 py-0.5 rounded text-sm font-mono border`
}
</script>

<style scoped>
.ebook-text {
  color: var(--ebook-text);
}

.heading-text {
  color: var(--ebook-text-heading);
}

.link-text {
  color: var(--ebook-link-color);
}

.border-link {
  border-color: var(--ebook-link-color);
}

.citation-text {
  color: #0d9488;
}

.inline-code {
  background: var(--ebook-inline-code-bg);
  color: var(--ebook-inline-code-text);
  border-color: var(--ebook-inline-code-border);
}
</style>
