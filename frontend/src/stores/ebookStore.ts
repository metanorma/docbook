import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'

export type Theme = 'day' | 'sepia' | 'night' | 'oled'
export type FontFamily = 'sans' | 'serif'
export type ContentWidth = 'narrow' | 'default' | 'wide'
export type LineHeight = 'compact' | 'comfortable' | 'relaxed' | 'spacious'
export type TextAlignment = 'left' | 'justify'
export type ReadingMode = 'scroll' | 'paged'

const STORAGE_KEY = 'docbook_ebook_preferences'

export const CONTENT_WIDTHS: Record<ContentWidth, string> = {
  narrow: '38rem',
  default: '58rem',
  wide: '82rem',
}

export const LINE_HEIGHTS: Record<LineHeight, string> = {
  compact: '1.4',
  comfortable: '1.6',
  relaxed: '1.8',
  spacious: '2.0',
}

const DEFAULTS = {
  fontSize: 18,
  fontFamily: 'sans' as FontFamily,
  contentWidth: 'default' as ContentWidth,
  theme: 'day' as Theme,
  lineHeight: 'comfortable' as LineHeight,
  textAlignment: 'left' as TextAlignment,
  hyphenation: false,
  showProgress: true,
  readingMode: 'scroll' as ReadingMode,
  refCardMode: false,
}

function loadPreferences(): Partial<typeof DEFAULTS> {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored) return JSON.parse(stored)
  } catch {}
  return {}
}

function savePreferences(prefs: Record<string, unknown>) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs))
  } catch {}
}

function applyThemeClass(theme: Theme) {
  const html = document.documentElement
  html.classList.remove('theme-day', 'theme-sepia', 'theme-night', 'theme-oled')
  html.classList.add(`theme-${theme}`)
  const isDark = theme === 'night' || theme === 'oled'
  html.classList.toggle('dark', isDark)
}

const THEME_ORDER: Theme[] = ['day', 'sepia', 'night', 'oled']

// One-time migration: remove old theme/font keys that were replaced by this store
try {
  localStorage.removeItem('docbook-theme')
  localStorage.removeItem('docbook-font')
} catch {}

export const useEbookStore = defineStore('ebook', () => {
  const prefs = loadPreferences()

  // State
  const fontSize = ref(prefs.fontSize ?? DEFAULTS.fontSize)
  const fontFamily = ref<FontFamily>(prefs.fontFamily ?? DEFAULTS.fontFamily)
  const contentWidth = ref<ContentWidth>(prefs.contentWidth ?? DEFAULTS.contentWidth)
  const theme = ref<Theme>(prefs.theme ?? DEFAULTS.theme)
  const lineHeight = ref<LineHeight>(prefs.lineHeight ?? DEFAULTS.lineHeight)
  const textAlignment = ref<TextAlignment>(prefs.textAlignment ?? DEFAULTS.textAlignment)
  const hyphenation = ref(prefs.hyphenation ?? DEFAULTS.hyphenation)
  const showProgress = ref(prefs.showProgress ?? DEFAULTS.showProgress)
  const readingMode = ref<ReadingMode>(prefs.readingMode ?? DEFAULTS.readingMode)
  const refCardMode = ref(prefs.refCardMode ?? DEFAULTS.refCardMode)

  // UI-only state (not persisted)
  const uiVisible = ref(true)
  const tocOpen = ref(false)
  const settingsOpen = ref(false)
  const focusMode = ref(false)

  // Apply theme on store initialization
  applyThemeClass(theme.value)

  // Apply font family on store initialization
  if (typeof document !== 'undefined') {
    document.body.classList.toggle('font-serif', fontFamily.value === 'serif')
    document.body.classList.toggle('font-sans', fontFamily.value === 'sans')
  }

  // Auto-save persisted fields
  watch(
    [fontSize, fontFamily, contentWidth, theme, lineHeight, textAlignment, hyphenation, showProgress, readingMode, refCardMode],
    () => {
      savePreferences({
        fontSize: fontSize.value,
        fontFamily: fontFamily.value,
        contentWidth: contentWidth.value,
        theme: theme.value,
        lineHeight: lineHeight.value,
        textAlignment: textAlignment.value,
        hyphenation: hyphenation.value,
        showProgress: showProgress.value,
        readingMode: readingMode.value,
        refCardMode: refCardMode.value,
      })
    },
    { immediate: true }
  )

  // Auto-apply theme changes
  watch(() => theme.value, (t) => applyThemeClass(t))

  // Actions
  function setFontSize(size: number) {
    fontSize.value = Math.max(12, Math.min(32, size))
  }

  function setFontFamily(f: FontFamily) {
    fontFamily.value = f
    document.body.classList.toggle('font-serif', f === 'serif')
    document.body.classList.toggle('font-sans', f === 'sans')
  }

  function setContentWidth(w: ContentWidth) {
    contentWidth.value = w
  }

  function setTheme(t: Theme) {
    theme.value = t
    applyThemeClass(t)
  }

  function cycleTheme() {
    const nextIndex = (THEME_ORDER.indexOf(theme.value) + 1) % THEME_ORDER.length
    setTheme(THEME_ORDER[nextIndex])
  }

  function setUiVisible(visible: boolean) {
    uiVisible.value = visible
  }

  function setLineHeight(lh: LineHeight) {
    lineHeight.value = lh
  }

  function setTextAlignment(ta: TextAlignment) {
    textAlignment.value = ta
  }

  function setHyphenation(h: boolean) {
    hyphenation.value = h
  }

  function setFocusMode(fm: boolean) {
    focusMode.value = fm
  }

  function toggleFocusMode() {
    focusMode.value = !focusMode.value
  }

  function setShowProgress(sp: boolean) {
    showProgress.value = sp
  }

  function setReadingMode(rm: ReadingMode) {
    readingMode.value = rm
  }

  function setRefCardMode(rcm: boolean) {
    refCardMode.value = rcm
  }

  function toggleToc() {
    tocOpen.value = !tocOpen.value
    if (tocOpen.value) settingsOpen.value = false
  }

  function toggleSettings() {
    settingsOpen.value = !settingsOpen.value
    if (settingsOpen.value) tocOpen.value = false
  }

  function closeAll() {
    tocOpen.value = false
    settingsOpen.value = false
  }

  function applyTheme() {
    applyThemeClass(theme.value)
  }

  function getThemeClass(): string {
    return `theme-${theme.value}`
  }

  function getCssVariables(): Record<string, string> {
    return {
      '--ebook-font-size': `${fontSize.value}px`,
      '--ebook-max-width': focusMode.value ? '100%' : CONTENT_WIDTHS[contentWidth.value],
      '--ebook-line-height': LINE_HEIGHTS[lineHeight.value],
      '--ebook-text-align': textAlignment.value,
      '--ebook-hyphens': hyphenation.value ? 'auto' : 'manual',
    }
  }

  return {
    // State
    fontSize, fontFamily, contentWidth, theme,
    lineHeight, textAlignment, hyphenation,
    showProgress, readingMode, refCardMode,
    uiVisible, tocOpen, settingsOpen, focusMode,

    // Actions
    setFontSize, setFontFamily, setContentWidth, setTheme,
    cycleTheme, setUiVisible, setLineHeight, setTextAlignment,
    setHyphenation, setFocusMode, toggleFocusMode, setShowProgress,
    setReadingMode, setRefCardMode, toggleToc, toggleSettings,
    closeAll, applyTheme,

    // Utilities
    getThemeClass, getCssVariables,
    CONTENT_WIDTHS, LINE_HEIGHTS,
  }
})
