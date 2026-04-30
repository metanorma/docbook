<template>
  <div v-if="visible" class="reading-progress-wrap">
    <div class="reading-progress" :style="{ width: `${progress}%` }"></div>
    <div class="reading-progress-glow" :style="{ left: `${progress}%` }"></div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  progress: number
  visible: boolean
}>()
</script>

<style scoped>
.reading-progress-wrap {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  z-index: 40;
}

.reading-progress {
  height: 100%;
  background: var(--chrome-accent);
  transition: width 0.15s ease-out;
  border-radius: 0 2px 2px 0;
}

.reading-progress-glow {
  position: absolute;
  top: -4px;
  width: 20px;
  height: 11px;
  background: radial-gradient(ellipse at center, var(--chrome-accent) 0%, transparent 70%);
  opacity: 0.6;
  transform: translateX(-50%);
  transition: left 0.15s ease-out;
  pointer-events: none;
}
</style>
