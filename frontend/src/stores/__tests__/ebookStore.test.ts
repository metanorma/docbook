import { describe, it, expect, beforeEach } from 'vitest'
import { nextTick } from 'vue'
import { setActivePinia, createPinia } from 'pinia'
import { useEbookStore } from '../ebookStore'

describe('useEbookStore', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  it('has correct defaults', () => {
    const store = useEbookStore()
    expect(store.fontSize).toBe(18)
    expect(store.fontFamily).toBe('sans')
    expect(store.contentWidth).toBe('default')
    expect(store.theme).toBe('day')
    expect(store.lineHeight).toBe('comfortable')
    expect(store.textAlignment).toBe('left')
    expect(store.hyphenation).toBe(false)
    expect(store.showProgress).toBe(true)
    expect(store.readingMode).toBe('scroll')
    expect(store.refCardMode).toBe(false)
  })

  it('sets font size with clamping', () => {
    const store = useEbookStore()
    store.setFontSize(20)
    expect(store.fontSize).toBe(20)
    store.setFontSize(5)
    expect(store.fontSize).toBe(12)
    store.setFontSize(100)
    expect(store.fontSize).toBe(32)
  })

  it('sets font family', () => {
    const store = useEbookStore()
    store.setFontFamily('serif')
    expect(store.fontFamily).toBe('serif')
  })

  it('sets content width', () => {
    const store = useEbookStore()
    store.setContentWidth('wide')
    expect(store.contentWidth).toBe('wide')
  })

  it('sets theme', () => {
    const store = useEbookStore()
    store.setTheme('night')
    expect(store.theme).toBe('night')
  })

  it('cycles through themes', () => {
    const store = useEbookStore()
    expect(store.theme).toBe('day')
    store.cycleTheme()
    expect(store.theme).toBe('sepia')
    store.cycleTheme()
    expect(store.theme).toBe('night')
    store.cycleTheme()
    expect(store.theme).toBe('oled')
    store.cycleTheme()
    expect(store.theme).toBe('day')
  })

  it('sets line height', () => {
    const store = useEbookStore()
    store.setLineHeight('spacious')
    expect(store.lineHeight).toBe('spacious')
  })

  it('sets text alignment', () => {
    const store = useEbookStore()
    store.setTextAlignment('justify')
    expect(store.textAlignment).toBe('justify')
  })

  it('toggles hyphenation', () => {
    const store = useEbookStore()
    expect(store.hyphenation).toBe(false)
    store.setHyphenation(true)
    expect(store.hyphenation).toBe(true)
  })

  it('toggles focus mode', () => {
    const store = useEbookStore()
    store.setFocusMode(true)
    expect(store.focusMode).toBe(true)
    store.toggleFocusMode()
    expect(store.focusMode).toBe(false)
  })

  it('toggles settings panel', () => {
    const store = useEbookStore()
    expect(store.settingsOpen).toBe(false)
    store.toggleSettings()
    expect(store.settingsOpen).toBe(true)
    expect(store.tocOpen).toBe(false)
  })

  it('toggles toc panel', () => {
    const store = useEbookStore()
    store.toggleToc()
    expect(store.tocOpen).toBe(true)
    expect(store.settingsOpen).toBe(false)
  })

  it('closeAll closes both panels', () => {
    const store = useEbookStore()
    store.toggleSettings()
    store.closeAll()
    expect(store.settingsOpen).toBe(false)
    expect(store.tocOpen).toBe(false)
  })

  it('returns theme class', () => {
    const store = useEbookStore()
    expect(store.getThemeClass()).toBe('theme-day')
    store.setTheme('night')
    expect(store.getThemeClass()).toBe('theme-night')
  })

  it('returns CSS variables', () => {
    const store = useEbookStore()
    const vars = store.getCssVariables()
    expect(vars['--ebook-font-size']).toBe('18px')
    expect(vars['--ebook-max-width']).toBe('58rem')
    expect(vars['--ebook-line-height']).toBe('1.6')
    expect(vars['--ebook-text-align']).toBe('left')
    expect(vars['--ebook-hyphens']).toBe('manual')
  })

  it('CSS variables reflect focus mode', () => {
    const store = useEbookStore()
    store.setFocusMode(true)
    const vars = store.getCssVariables()
    expect(vars['--ebook-max-width']).toBe('100%')
  })

  it('CSS variables reflect hyphenation', () => {
    const store = useEbookStore()
    store.setHyphenation(true)
    const vars = store.getCssVariables()
    expect(vars['--ebook-hyphens']).toBe('auto')
  })

  it('persists preferences to localStorage', async () => {
    const store = useEbookStore()
    store.setTheme('night')
    store.setFontSize(24)
    await nextTick()

    const stored = JSON.parse(localStorage.getItem('docbook_ebook_preferences')!)
    expect(stored.theme).toBe('night')
    expect(stored.fontSize).toBe(24)
  })

  it('loads preferences from localStorage', () => {
    localStorage.setItem('docbook_ebook_preferences', JSON.stringify({
      theme: 'sepia',
      fontSize: 22,
    }))

    // Create a new pinia instance to trigger store re-creation
    setActivePinia(createPinia())
    const store = useEbookStore()
    expect(store.theme).toBe('sepia')
    expect(store.fontSize).toBe(22)
  })
})
