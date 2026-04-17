<template>
  <div v-if="visible" class="reading-progress" :style="{ width: `${progress}%` }"></div>
</template>

<script setup lang="ts">
defineProps<{
  progress: number
  visible: boolean
}>()
</script>

<style scoped>
.reading-progress {
  position: fixed;
  top: 0;
  left: 0;
  height: 3px;
  background: var(--chrome-accent);
  z-index: 40;
  transition: width 0.1s ease-out;
  opacity: 0.85;
  border-radius: 0 1px 1px 0;
}

.reading-progress::after {
  content: '';
  position: absolute;
  right: 0;
  top: 0;
  width: 20px;
  height: 100%;
  background: linear-gradient(to right, var(--chrome-accent), transparent);
  opacity: 0.4;
}
</style>
