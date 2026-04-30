<template>
  <component :is="wrapInMarks(node.marks || [])">
    {{ node.text }}
  </component>
</template>

<script setup lang="ts">
import { h, type VNode, type Component } from 'vue'

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

function markToTag(mark: Mark): string {
  switch (mark.type) {
    case 'emphasis':
    case 'italic':
      return 'em'
    case 'strong':
      return 'strong'
    case 'code':
      return 'code'
    case 'link':
    case 'xref':
      return 'a'
    case 'subscript':
      return 'sub'
    case 'superscript':
      return 'sup'
    case 'citation':
    case 'tag':
      return 'span'
    default:
      return 'span'
  }
}

function markAttrs(mark: Mark): Record<string, any> {
  switch (mark.type) {
    case 'code':
      return { class: getCodeClass(mark) }
    case 'link':
      if (mark.attrs?.linkend) {
        return { href: '#' + mark.attrs.linkend }
      }
      return {
        href: mark.attrs?.href,
        target: '_blank',
        rel: 'noopener noreferrer',
        class: 'link-text hover:underline external-link',
      }
    case 'xref':
      return {
        href: `#${mark.attrs?.linkend}`,
        class: 'xref link-text',
      }
    case 'citation':
      return { class: 'citation citation-text italic' }
    case 'tag':
      return { class: 'tag' }
    case 'emphasis':
      return { class: 'italic ebook-text' }
    case 'strong':
      return { class: 'font-bold heading-text' }
    case 'italic':
      return { class: 'italic ebook-text' }
    case 'subscript':
    case 'superscript':
      return {}
    default:
      return {}
  }
}

function getCodeClass(mark: Mark): string {
  const role = mark.attrs?.role || 'literal'
  return `code-${role} inline-code px-1.5 py-0.5 rounded text-sm font-mono border`
}

function wrapInMarks(marks: Mark[]): Component {
  return {
    setup(_, { slots }) {
      return () => {
        // Build the VNode tree from outermost to innermost mark
        let inner: VNode | null = null

        if (marks.length === 0) {
          return h('span', {}, slots.default?.())
        }

        // Build from innermost mark outward
        for (let i = marks.length - 1; i >= 0; i--) {
          const mark = marks[i]
          const tag = markToTag(mark)
          const attrs = markAttrs(mark)

          if (inner) {
            inner = h(tag, attrs, inner)
          } else {
            // Innermost mark wraps the slot content (the text)
            inner = h(tag, attrs, slots.default?.())
          }
        }

        return inner || h('span', {}, slots.default?.())
      }
    },
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

.link-text {
  color: var(--ebook-link-color);
  transition: color 0.15s ease;
}

.xref {
  text-decoration: none;
  border-bottom: 1px dashed color-mix(in srgb, var(--ebook-link-color) 40%, transparent);
  transition: border-bottom-color 0.15s ease, color 0.15s ease;
}

.xref:hover {
  border-bottom-color: var(--ebook-link-color);
  border-bottom-style: solid;
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

.external-link::after {
  content: '↗';
  font-size: 0.65em;
  vertical-align: super;
  margin-left: 2px;
  opacity: 0.5;
}

.external-link:hover::after {
  opacity: 1;
}
</style>
