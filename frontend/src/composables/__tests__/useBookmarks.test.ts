import { describe, it, expect, beforeEach } from 'vitest'
import { useBookmarks } from '../useBookmarks'

// Mock localStorage
const store: Record<string, string> = {}
beforeEach(() => {
  Object.keys(store).forEach(k => delete store[k])
})

Object.defineProperty(globalThis, 'localStorage', {
  value: {
    getItem: (key: string) => store[key] ?? null,
    setItem: (key: string, value: string) => { store[key] = value },
    removeItem: (key: string) => { delete store[key] },
    clear: () => Object.keys(store).forEach(k => delete store[k]),
    get length() { return Object.keys(store).length },
    key: (i: number) => Object.keys(store)[i] ?? null,
  },
})

describe('useBookmarks', () => {
  it('starts with empty bookmarks', () => {
    const { bookmarks } = useBookmarks('Test Book')
    expect(bookmarks.value).toHaveLength(0)
  })

  it('adds a bookmark', () => {
    const { bookmarks, add } = useBookmarks('Test Book')
    const bm = add('ch1', 'Chapter 1')
    expect(bookmarks.value).toHaveLength(1)
    expect(bm.sectionId).toBe('ch1')
    expect(bm.title).toBe('Chapter 1')
  })

  it('does not add duplicate bookmarks', () => {
    const { bookmarks, add } = useBookmarks('Test Book')
    add('ch1', 'Chapter 1')
    add('ch1', 'Chapter 1')
    expect(bookmarks.value).toHaveLength(1)
  })

  it('removes a bookmark', () => {
    const { bookmarks, add, remove } = useBookmarks('Test Book')
    add('ch1', 'Chapter 1')
    remove('ch1')
    expect(bookmarks.value).toHaveLength(0)
  })

  it('toggles bookmark on and off', () => {
    const { bookmarks, toggle } = useBookmarks('Test Book')
    toggle('ch1', 'Chapter 1')
    expect(bookmarks.value).toHaveLength(1)
    toggle('ch1', 'Chapter 1')
    expect(bookmarks.value).toHaveLength(0)
  })

  it('checks if a section is bookmarked', () => {
    const { isBookmarked, add } = useBookmarks('Test Book')
    expect(isBookmarked('ch1')).toBe(false)
    add('ch1', 'Chapter 1')
    expect(isBookmarked('ch1')).toBe(true)
  })

  it('persists to localStorage', () => {
    const { add } = useBookmarks('Test Book')
    add('ch1', 'Chapter 1')

    const key = 'docbook_bookmarks_Test_Book'
    expect(store[key]).toBeDefined()
    const stored = JSON.parse(store[key])
    expect(stored).toHaveLength(1)
    expect(stored[0].sectionId).toBe('ch1')
  })

  it('loads from localStorage on init', () => {
    const key = 'docbook_bookmarks_Another_Book'
    store[key] = JSON.stringify([{ id: 'bm_1', sectionId: 's1', title: 'Section 1', snippet: '', createdAt: Date.now() }])

    const { bookmarks } = useBookmarks('Another Book')
    expect(bookmarks.value).toHaveLength(1)
    expect(bookmarks.value[0].sectionId).toBe('s1')
  })

  it('truncates snippet to 120 chars', () => {
    const { add } = useBookmarks('Test Book')
    const longSnippet = 'x'.repeat(200)
    const bm = add('ch1', 'Chapter 1', longSnippet)
    expect(bm.snippet.length).toBe(120)
  })
})
