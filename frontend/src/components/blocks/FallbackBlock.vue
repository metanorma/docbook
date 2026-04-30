<template>
  <p class="mb-3 ebook-text">{{ extractText(block) }}</p>
</template>

<script setup lang="ts">
import type { MirrorBlockNode } from '@/stores/documentStore'
import { extractText } from '@/utils/nodeExtract'

defineProps<{ block: MirrorBlockNode }>()
</script>

<style scoped>
.ebook-text { color: var(--ebook-text); }
</style>
