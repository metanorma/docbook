import { defineStore } from 'pinia'
import { ref } from 'vue'

export type Theme = 'light' | 'dark' | 'system'
export type FontFamily = 'sans' | 'serif'

export const useUiStore = defineStore('ui', () => {
  const theme = ref<Theme>((localStorage.getItem('docbook-theme') as Theme) || 'system')
  const fontFamily = ref<FontFamily>((localStorage.getItem('docbook-font') as FontFamily) || 'sans')
  const sidebarOpen = ref(false)
  const searchOpen = ref(false)
  const activeSectionId = ref<string | null>(null)

  function initTheme() {
    applyTheme()
  }

  function applyTheme() {
    const isDark = theme.value === 'dark' ||
      (theme.value === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)
    document.documentElement.classList.toggle('dark', isDark)
  }

  function setTheme(newTheme: Theme) {
    theme.value = newTheme
    localStorage.setItem('docbook-theme', newTheme)
    applyTheme()
  }

  function toggleTheme() {
    if (theme.value === 'light') {
      setTheme('dark')
    } else if (theme.value === 'dark') {
      setTheme('system')
    } else {
      setTheme('light')
    }
  }

  function setFontFamily(newFont: FontFamily) {
    fontFamily.value = newFont
    localStorage.setItem('docbook-font', newFont)
    document.body.classList.toggle('font-serif', newFont === 'serif')
    document.body.classList.toggle('font-sans', newFont === 'sans')
  }

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

  // Watch for system theme changes
  if (typeof window !== 'undefined') {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (theme.value === 'system') {
        applyTheme()
      }
    })
  }

  return {
    theme,
    fontFamily,
    sidebarOpen,
    searchOpen,
    activeSectionId,
    initTheme,
    applyTheme,
    setTheme,
    toggleTheme,
    setFontFamily,
    openSidebar,
    closeSidebar,
    toggleSidebar,
    openSearch,
    closeSearch,
    setActiveSection
  }
})
