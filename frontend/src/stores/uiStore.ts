import { defineStore } from 'pinia'
import { ref } from 'vue'

// One-time migration: remove old theme/font keys that were replaced by useEbookStore
try {
  localStorage.removeItem('docbook-theme')
  localStorage.removeItem('docbook-font')
} catch {}

export const useUiStore = defineStore('ui', () => {
  const sidebarOpen = ref(false)
  const searchOpen = ref(false)
  const activeSectionId = ref<string | null>(null)

  function openSidebar() {
    sidebarOpen.value = true
  }

  function closeSidebar() {
    sidebarOpen.value = false
  }

  function toggleSidebar() {
    sidebarOpen.value = !sidebarOpen.value
  }

  function openSearch() {
    searchOpen.value = true
  }

  function closeSearch() {
    searchOpen.value = false
  }

  function setActiveSection(id: string) {
    activeSectionId.value = id
  }

  return {
    sidebarOpen,
    searchOpen,
    activeSectionId,
    openSidebar,
    closeSidebar,
    toggleSidebar,
    openSearch,
    closeSearch,
    setActiveSection
  }
})
