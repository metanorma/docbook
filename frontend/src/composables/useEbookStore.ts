import { reactive, computed, watch } from 'vue'

export type ReadingMode = 'scroll' | 'page' | 'chapter' | 'reference'
export type Theme = 'day' | 'sepia' | 'night' | 'oled'

interface EbookState {
  readingMode: ReadingMode
  fontSize: number
  fontWeight: number
  lineHeight: number
  margin: number
  theme: Theme
  uiVisible: boolean
  tocOpen: boolean
  settingsOpen: boolean
}

const STORAGE_KEY = 'docbook_ebook_preferences'

// Default state
const defaultState: EbookState = {
  readingMode: 'scroll',
  fontSize: 18,
  fontWeight: 400,
  lineHeight: 1.6,
  margin: 48,
  theme: 'day',
  uiVisible: true,
  tocOpen: false,
  settingsOpen: false
}

// Load from localStorage
function loadPreferences(): Partial<EbookState> {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored) {
      return JSON.parse(stored)
    }
  } catch (e) {
    console.warn('Failed to load preferences:', e)
  }
  return {}
}

// Save to localStorage
function savePreferences(state: EbookState) {
  try {
    const { uiVisible, tocOpen, settingsOpen, ...persisted } = state
    localStorage.setItem(STORAGE_KEY, JSON.stringify(persisted))
  } catch (e) {
    console.warn('Failed to save preferences:', e)
  }
}

// Global reactive state - settingsOpen ALWAYS starts false regardless of localStorage
const loadedPrefs = loadPreferences()
// Ensure settingsOpen is never true from localStorage
delete loadedPrefs.settingsOpen
const state = reactive<EbookState>(Object.assign({}, defaultState, loadedPrefs, { settingsOpen: false }))

// Auto-save when persisted fields change (not deep watch for performance)
watch(
  () => ({
    readingMode: state.readingMode,
    fontSize: state.fontSize,
    fontWeight: state.fontWeight,
    lineHeight: state.lineHeight,
    margin: state.margin,
    theme: state.theme
  }),
  () => savePreferences(state),
  { immediate: true }
)

// Theme application function - applies Tailwind dark class based on theme
function applyTheme() {
  const isDark = state.theme === 'night' || state.theme === 'oled'
  document.documentElement.classList.toggle('dark', isDark)
}

// Apply theme on load and when theme changes
applyTheme()
watch(() => state.theme, applyTheme)

export function useEbookStore() {
  // Computed getters - these ARE reactive and will auto-unwrap in templates
  const readingMode = computed(() => state.readingMode)
  const fontSize = computed(() => state.fontSize)
  const fontWeight = computed(() => state.fontWeight)
  const lineHeight = computed(() => state.lineHeight)
  const margin = computed(() => state.margin)
  const theme = computed(() => state.theme)
  const uiVisible = computed(() => state.uiVisible)
  const tocOpen = computed(() => state.tocOpen)
  const settingsOpen = computed(() => state.settingsOpen)

  // Actions
  function setReadingMode(mode: ReadingMode) {
    state.readingMode = mode
  }

  function setFontSize(size: number) {
    state.fontSize = Math.max(12, Math.min(32, size))
  }

  function setFontWeight(weight: number) {
    state.fontWeight = Math.max(300, Math.min(700, weight))
  }

  function setLineHeight(height: number) {
    state.lineHeight = Math.max(1.2, Math.min(2.0, height))
  }

  function setMargin(m: number) {
    state.margin = Math.max(16, Math.min(96, m))
  }

  function setTheme(t: Theme) {
    state.theme = t
    applyTheme()
  }

  function setUiVisible(visible: boolean) {
    state.uiVisible = visible
  }

  function toggleToc() {
    state.tocOpen = !state.tocOpen
    if (state.tocOpen) {
      state.settingsOpen = false
    }
  }

  function toggleSettings() {
    state.settingsOpen = !state.settingsOpen
    if (state.settingsOpen) {
      state.tocOpen = false
    }
  }

  function closeAll() {
    state.tocOpen = false
    state.settingsOpen = false
  }

  // Theme CSS class
  function getThemeClass(): string {
    return `theme-${state.theme}`
  }

  // Generate CSS variables object
  function getCssVariables(): Record<string, string | number> {
    return {
      '--ebook-font-size': `${state.fontSize}px`,
      '--ebook-font-weight': state.fontWeight,
      '--ebook-line-height': state.lineHeight,
      '--ebook-margin': `${state.margin}px`,
    }
  }

  return {
    // Computed getters (reactive, auto-unwrap in templates)
    readingMode,
    fontSize,
    fontWeight,
    lineHeight,
    margin,
    theme,
    uiVisible,
    tocOpen,
    settingsOpen,

    // Actions
    setReadingMode,
    setFontSize,
    setFontWeight,
    setLineHeight,
    setMargin,
    setTheme,
    applyTheme,
    setUiVisible,
    toggleToc,
    toggleSettings,
    closeAll,

    // Utilities
    getThemeClass,
    getCssVariables
  }
}
