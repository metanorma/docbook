import { ref, watch } from 'vue'

export interface Bookmark {
  id: string
  sectionId: string
  title: string
  snippet: string
  createdAt: number
}

const STORAGE_KEY = 'docbook_bookmarks'

export function useBookmarks(docTitle: string) {
  const bookmarks = ref<Bookmark[]>([])

  function storageKey(): string {
    return `${STORAGE_KEY}_${(docTitle || 'default').replace(/\s+/g, '_')}`
  }

  function load() {
    try {
      const stored = localStorage.getItem(storageKey())
      if (stored) {
        bookmarks.value = JSON.parse(stored)
      }
    } catch (e) {
      console.warn('Failed to load bookmarks:', e)
    }
  }

  function save() {
    try {
      localStorage.setItem(storageKey(), JSON.stringify(bookmarks.value))
    } catch (e) {
      console.warn('Failed to save bookmarks:', e)
    }
  }

  function add(sectionId: string, title: string, snippet: string = ''): Bookmark {
    // Don't add duplicates
    const existing = bookmarks.value.find(b => b.sectionId === sectionId)
    if (existing) return existing

    const bookmark: Bookmark = {
      id: `bm_${Date.now()}`,
      sectionId,
      title,
      snippet: snippet.slice(0, 120),
      createdAt: Date.now(),
    }
    bookmarks.value = [bookmark, ...bookmarks.value]
    save()
    return bookmark
  }

  function remove(sectionId: string) {
    bookmarks.value = bookmarks.value.filter(b => b.sectionId !== sectionId)
    save()
  }

  function toggle(sectionId: string, title: string, snippet: string = '') {
    const existing = bookmarks.value.find(b => b.sectionId === sectionId)
    if (existing) {
      remove(sectionId)
    } else {
      add(sectionId, title, snippet)
    }
  }

  function isBookmarked(sectionId: string): boolean {
    return bookmarks.value.some(b => b.sectionId === sectionId)
  }

  // Load on initialization
  load()

  return {
    bookmarks,
    add,
    remove,
    toggle,
    isBookmarked,
  }
}
