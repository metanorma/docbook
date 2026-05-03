import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useUiStore } from '../uiStore'

describe('useUiStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('has correct defaults', () => {
    const store = useUiStore()
    expect(store.sidebarOpen).toBe(false)
    expect(store.searchOpen).toBe(false)
    expect(store.activeSectionId).toBeNull()
    expect(store.tocFollowFocus).toBe(true)
  })

  it('opens sidebar', () => {
    const store = useUiStore()
    store.openSidebar()
    expect(store.sidebarOpen).toBe(true)
  })

  it('closes sidebar', () => {
    const store = useUiStore()
    store.openSidebar()
    store.closeSidebar()
    expect(store.sidebarOpen).toBe(false)
  })

  it('toggles sidebar', () => {
    const store = useUiStore()
    store.toggleSidebar()
    expect(store.sidebarOpen).toBe(true)
    store.toggleSidebar()
    expect(store.sidebarOpen).toBe(false)
  })

  it('opens search', () => {
    const store = useUiStore()
    store.openSearch()
    expect(store.searchOpen).toBe(true)
  })

  it('closes search', () => {
    const store = useUiStore()
    store.openSearch()
    store.closeSearch()
    expect(store.searchOpen).toBe(false)
  })

  it('sets active section', () => {
    const store = useUiStore()
    store.setActiveSection('ch1')
    expect(store.activeSectionId).toBe('ch1')
  })

  it('sets toc follow focus', () => {
    const store = useUiStore()
    store.setTocFollowFocus(false)
    expect(store.tocFollowFocus).toBe(false)
  })
})
