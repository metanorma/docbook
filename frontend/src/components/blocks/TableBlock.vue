<template>
  <div :id="block.attrs?.xml_id" class="mb-4">
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
              <MirrorRenderer :blocks="cell.content || []" />
            </th>
          </tr>
        </thead>
        <tbody v-for="(section, si) in (block.content || []).filter(s => s.type === 'table_body')" :key="'b'+si">
          <tr v-for="(row, ri) in section.content" :key="ri" class="table-row border-b border-ebook-border">
            <td v-for="(cell, ci) in row.content" :key="ci"
                class="px-3 py-2 ebook-text border border-ebook-border"
                :colspan="cell.attrs?.nameend ? getColSpan(cell.attrs) : undefined"
                :rowspan="cell.attrs?.morerows ? parseInt(cell.attrs.morerows) + 1 : undefined">
              <MirrorRenderer :blocks="cell.content || []" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import { useDocumentStore } from '@/stores/documentStore'
import MirrorRenderer from '@/components/MirrorRenderer.vue'

defineProps<{ block: MirrorBlockNode }>()

const documentStore = useDocumentStore()

function getNumbering(id: string | undefined): string {
  if (!id) return ''
  return documentStore.getNumbering(id)
}

function getColSpan(attrs: Record<string, string | undefined> | undefined): number | undefined {
  if (!attrs?.namest || !attrs?.nameend) return undefined
  const cols = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const start = cols.indexOf(attrs.namest.toUpperCase())
  const end = cols.indexOf(attrs.nameend.toUpperCase())
  return start >= 0 && end >= 0 ? end - start + 1 : undefined
}
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
.muted-text { color: var(--ebook-text-muted); }
.border-ebook-border { border-color: var(--ebook-border); }
.table-scroll-wrapper { overflow-x: auto; -webkit-overflow-scrolling: touch; border-radius: 6px; border: 1px solid var(--ebook-border); }
.table-scroll-wrapper table { min-width: 400px; }
.table-scroll-wrapper thead th { position: sticky; top: 0; background: var(--ebook-bg-secondary); z-index: 1; }
.table-row:nth-child(even) { background: color-mix(in srgb, var(--ebook-text) 3%, var(--ebook-bg)); }
</style>
