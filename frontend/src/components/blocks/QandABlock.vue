<template>
  <section v-if="block.type === 'qandaset'" :id="block.attrs?.xml_id" class="qandaset-block">
    <h3 v-if="block.attrs?.title" class="qandaset-heading">{{ block.attrs.title }}</h3>
    <div class="qandaset-entries">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </section>
  <div v-else-if="block.type === 'qandaentry'" :id="block.attrs?.xml_id" class="qanda-entry">
    <MirrorRenderer :blocks="block.content || []" />
  </div>
  <div v-else-if="block.type === 'question'" class="question-block" @click="toggleAnswer" role="button" tabindex="0" @keydown.enter="toggleAnswer" @keydown.space.prevent="toggleAnswer">
    <div class="question-marker">
      <svg class="question-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/></svg>
    </div>
    <div class="question-content">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </div>
  <div v-else class="answer-block">
    <div class="answer-label">A:</div>
    <div class="answer-content">
      <MirrorRenderer :blocks="block.content || []" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

const props = defineProps<{ block: MirrorBlockNode }>()

// Module-level state shared across all QandABlock instances
const openEntries = new Map<string, boolean>()

function findEntryId(): string {
  const id = props.block.attrs?.xml_id
  if (!id) return ''
  const el = document.getElementById(id)
  if (!el) return id
  const entry = el.closest('.qanda-entry') as HTMLElement
  return entry?.id || id
}

function toggleAnswer() {
  const key = findEntryId()
  const open = !openEntries.get(key)
  openEntries.set(key, open)

  // Directly toggle DOM classes (simpler than reactive state for cross-instance sharing)
  const el = document.getElementById(key)
  if (el) {
    el.querySelectorAll('.answer-block').forEach(a => a.classList.toggle('answer-block--visible', open))
    el.querySelectorAll('.question-chevron').forEach(c => c.classList.toggle('question-chevron--open', open))
  }
}
</script>

<style scoped>
.qandaset-block {
  margin: 1.5rem 0;
  border-left: 3px solid var(--ebook-accent);
  padding-left: 1rem;
}

.qandaset-heading {
  font-size: 1.15rem;
  font-weight: 600;
  color: var(--ebook-text-heading);
  margin: 0 0 1rem;
}

.qandaset-entries {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.qanda-entry {
  padding: 0.75rem 1rem;
  background: var(--ebook-bg-secondary);
  border-radius: 8px;
  border: 1px solid var(--ebook-border);
  transition: border-color 0.15s ease;
}

.qanda-entry:hover {
  border-color: color-mix(in srgb, var(--ebook-accent) 30%, var(--ebook-border));
}

.question-block {
  display: flex;
  gap: 0.5rem;
  align-items: flex-start;
  cursor: pointer;
  user-select: none;
  padding: 2px 0;
}

.question-marker {
  flex-shrink: 0;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 2px;
}

.question-chevron {
  width: 14px;
  height: 14px;
  color: var(--ebook-accent);
  transition: transform 0.2s ease;
  opacity: 0.7;
}

.question-chevron--open {
  transform: rotate(90deg);
  opacity: 1;
}

.question-block:hover .question-chevron {
  opacity: 1;
}

.question-content {
  flex: 1;
  min-width: 0;
  color: var(--ebook-text);
  font-weight: 500;
}

.answer-block {
  display: flex;
  gap: 0.5rem;
  align-items: flex-start;
  margin-top: 0.25rem;
  padding-left: 0.5rem;
  border-left: 2px solid var(--ebook-border);
  max-height: 0;
  overflow: hidden;
  opacity: 0;
  transition: max-height 0.3s cubic-bezier(0.16, 1, 0.3, 1),
              opacity 0.2s ease,
              margin-top 0.2s ease;
}

.answer-block--visible {
  max-height: 2000px;
  opacity: 1;
  margin-top: 0.5rem;
}

.answer-label {
  font-weight: 700;
  color: var(--ebook-text-muted);
  flex-shrink: 0;
  font-size: 0.9em;
}

.answer-content {
  flex: 1;
  min-width: 0;
  color: var(--ebook-text);
}
</style>
