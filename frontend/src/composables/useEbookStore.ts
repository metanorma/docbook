import { reactive, computed, watch } from 'vue'

export type Theme = 'day' | 'sepia' | 'night' | 'oled'
export type FontFamily = 'sans' | 'serif'
export type ContentWidth = 'narrow' | 'default' | 'wide'
export type LineHeight = 'compact' | 'comfortable' | 'relaxed' | 'spacious'
export type TextAlignment = 'left' | 'justify'
export type ReadingMode = 'scroll' | 'paged'

interface EbookState {
  fontSize: number
  fontFamily: FontFamily
  contentWidth: ContentWidth
  theme: Theme
  uiVisible: boolean
  tocOpen: boolean
  settingsOpen: boolean
  lineHeight: LineHeight
  textAlignment: TextAlignment
  hyphenation: boolean
  focusMode: boolean
  showProgress: boolean
  readingMode: ReadingMode
  refCardMode: boolean
}

const STORAGE_KEY = 'docbook_ebook_preferences'

// Constants
const CONTENT_WIDTHS: Record<ContentWidth, string> = {
  narrow: '38rem',
  default: '58rem',
  wide: '82rem',
}

const LINE_HEIGHTS: Record<LineHeight, string> = {
  compact: '1.4',
  comfortable: '1.6',
  relaxed: '1.8',
  spacious: '2.0',
}

// Default state
const defaultState: EbookState = {
  fontSize: 18,
  fontFamily: 'sans',
  contentWidth: 'default',
  theme: 'day',
  uiVisible: true,
  tocOpen: false,
  settingsOpen: false,
  lineHeight: 'comfortable',
  textAlignment: 'left',
  hyphenation: false,
  focusMode: false,
  showProgress: true,
  readingMode: 'scroll',
  refCardMode: false,
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
    const { uiVisible, tocOpen, settingsOpen, focusMode, ...persisted } = state
    localStorage.setItem(STORAGE_KEY, JSON.stringify(persisted))
  } catch (e) {
    console.warn('Failed to save preferences:', e)
  }
}

// Global reactive state - settingsOpen ALWAYS starts false regardless of localStorage
const loadedPrefs = loadPreferences()
// Ensure settingsOpen is never true from localStorage
delete loadedPrefs.settingsOpen
delete loadedPrefs.focusMode
const state = reactive<EbookState>(Object.assign({}, defaultState, loadedPrefs, { settingsOpen: false, focusMode: false }))

// Auto-save when persisted fields change (not deep watch for performance)
watch(
  () => ({
    fontSize: state.fontSize,
    fontFamily: state.fontFamily,
    contentWidth: state.contentWidth,
    theme: state.theme,
    lineHeight: state.lineHeight,
    textAlignment: state.textAlignment,
    hyphenation: state.hyphenation,
    showProgress: state.showProgress,
    readingMode: state.readingMode,
    refCardMode: state.refCardMode,
  }),
  () => savePreferences(state),
  { immediate: true }
)

// Theme application function - applies theme class to <html> so CSS variables
// cascade to all elements including Teleported modals
function applyTheme() {
  const html = document.documentElement
  html.classList.remove('theme-day', 'theme-sepia', 'theme-night', 'theme-oled')
  html.classList.add(`theme-${state.theme}`)
  const isDark = state.theme === 'night' || state.theme === 'oled'
  html.classList.toggle('dark', isDark)
}

// Apply theme on load and when theme changes
applyTheme()
watch(() => state.theme, applyTheme)

export function useEbookStore() {
  // Computed getters - these ARE reactive and will auto-unwrap in templates
  const fontSize = computed(() => state.fontSize)
  const fontFamily = computed(() => state.fontFamily)
  const contentWidth = computed(() => state.contentWidth)
  const theme = computed(() => state.theme)
  const uiVisible = computed(() => state.uiVisible)
  const tocOpen = computed(() => state.tocOpen)
  const settingsOpen = computed(() => state.settingsOpen)
  const lineHeight = computed(() => state.lineHeight)
  const textAlignment = computed(() => state.textAlignment)
  const hyphenation = computed(() => state.hyphenation)
  const focusMode = computed(() => state.focusMode)
  const showProgress = computed(() => state.showProgress)
  const readingMode = computed(() => state.readingMode)
  const refCardMode = computed(() => state.refCardMode)

  // Actions
  function setFontSize(size: number) {
    state.fontSize = Math.max(12, Math.min(32, size))
  }

  function setFontFamily(f: FontFamily) {
    state.fontFamily = f
    document.body.classList.toggle('font-serif', f === 'serif')
    document.body.classList.toggle('font-sans', f === 'sans')
  }

  function setContentWidth(w: ContentWidth) {
    state.contentWidth = w
  }

  function setTheme(t: Theme) {
    state.theme = t
    applyTheme()
  }

  function setUiVisible(visible: boolean) {
    state.uiVisible = visible
  }

  function setLineHeight(lh: LineHeight) {
    state.lineHeight = lh
  }

  function setTextAlignment(ta: TextAlignment) {
    state.textAlignment = ta
  }

  function setHyphenation(h: boolean) {
    state.hyphenation = h
  }

  function setFocusMode(fm: boolean) {
    state.focusMode = fm
  }

  function toggleFocusMode() {
    state.focusMode = !state.focusMode
  }

  function setShowProgress(sp: boolean) {
    state.showProgress = sp
  }

  function setReadingMode(rm: ReadingMode) {
    state.readingMode = rm
  }

  function setRefCardMode(rcm: boolean) {
    state.refCardMode = rcm
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

  // Generate CSS variables object for direct application on content elements
  function getCssVariables(): Record<string, string> {
    return {
      '--ebook-font-size': `${state.fontSize}px`,
      '--ebook-max-width': state.focusMode ? '100%' : CONTENT_WIDTHS[state.contentWidth],
      '--ebook-line-height': LINE_HEIGHTS[state.lineHeight],
      '--ebook-text-align': state.textAlignment,
      '--ebook-hyphens': state.hyphenation ? 'auto' : 'manual',
    }
  }

  // Apply font family on load
  if (typeof document !== 'undefined') {
    document.body.classList.toggle('font-serif', state.fontFamily === 'serif')
    document.body.classList.toggle('font-sans', state.fontFamily === 'sans')
  }

  return {
    // Computed getters (reactive, auto-unwrap in templates)
    fontSize,
    fontFamily,
    contentWidth,
    theme,
    uiVisible,
    tocOpen,
    settingsOpen,
    lineHeight,
    textAlignment,
    hyphenation,
    focusMode,
    showProgress,
    readingMode,
    refCardMode,

    // Actions
    setFontSize,
    setFontFamily,
    setContentWidth,
    setTheme,
    applyTheme,
    setUiVisible,
    setLineHeight,
    setTextAlignment,
    setHyphenation,
    setFocusMode,
    toggleFocusMode,
    setShowProgress,
    setReadingMode,
    setRefCardMode,
    toggleToc,
    toggleSettings,
    closeAll,

    // Utilities
    getThemeClass,
    getCssVariables,
    CONTENT_WIDTHS,
    LINE_HEIGHTS,
  }
}
