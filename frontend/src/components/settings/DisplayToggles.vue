<template>
  <section class="settings-section" style="--delay: 3">
    <h3 class="settings-label">Advanced</h3>

    <!-- Hyphenation -->
    <div class="settings-row">
      <span class="settings-sublabel">Hyphens</span>
      <ToggleSwitch
        :model-value="currentHyphenation"
        @update:model-value="ebookStore.setHyphenation($event)"
        label="Hyphenation"
      />
    </div>

    <!-- Progress Bar -->
    <div class="settings-row">
      <span class="settings-sublabel">Progress</span>
      <ToggleSwitch
        :model-value="currentShowProgress"
        @update:model-value="ebookStore.setShowProgress($event)"
        label="Progress bar"
      />
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useEbookStore } from '@/stores/ebookStore'
import ToggleSwitch from '@/components/ui/ToggleSwitch.vue'

const ebookStore = useEbookStore()

const currentHyphenation = computed(() => ebookStore.hyphenation)
const currentShowProgress = computed(() => ebookStore.showProgress)
</script>

<style scoped src="./settings-base.css"></style>
