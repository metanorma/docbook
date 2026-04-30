<template>
  <button
    @click="$emit('update:modelValue', !modelValue)"
    class="toggle-switch"
    :class="{ 'toggle-switch--on': modelValue }"
    role="switch"
    :aria-checked="modelValue"
    :aria-label="label"
  >
    <span class="toggle-switch-thumb"></span>
  </button>
</template>

<script setup lang="ts">
defineProps<{
  modelValue: boolean
  label: string
}>()

defineEmits<{
  'update:modelValue': [value: boolean]
}>()
</script>

<style scoped>
.toggle-switch {
  position: relative;
  width: 44px;
  height: 24px;
  border-radius: 999px;
  background: var(--chrome-border);
  border: none;
  cursor: pointer;
  transition: background 0.2s ease;
  flex-shrink: 0;
}

.toggle-switch:focus-visible {
  outline: 2px solid var(--chrome-accent);
  outline-offset: 2px;
}

.toggle-switch--on {
  background: var(--chrome-accent);
}

.toggle-switch-thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: white;
  transition: transform 0.2s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.toggle-switch--on .toggle-switch-thumb {
  transform: translateX(20px);
}
</style>
