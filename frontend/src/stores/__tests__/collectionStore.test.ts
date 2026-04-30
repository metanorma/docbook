import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useCollectionStore } from '../collectionStore'

describe('useCollectionStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('starts with empty books', () => {
    const store = useCollectionStore()
    expect(store.books).toHaveLength(0)
    expect(store.collectionName).toBe('My Library')
  })

  it('loads collection data', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test Collection',
      books: [
        { id: 'b1', title: 'Book One', source: '/b1.json' },
        { id: 'b2', title: 'Book Two', source: '/b2.json' },
      ],
    })
    expect(store.collectionName).toBe('Test Collection')
    expect(store.books).toHaveLength(2)
    expect(store.books[0].title).toBe('Book One')
  })

  it('loads from window global', async () => {
    ;(globalThis as any).DOCBOOK_COLLECTION = {
      name: 'Window Collection',
      books: [{ id: 'w1', title: 'Window Book', source: '/w1.json' }],
    }
    const store = useCollectionStore()
    await store.loadFromWindow()
    expect(store.collectionName).toBe('Window Collection')
    expect(store.books).toHaveLength(1)
    delete (globalThis as any).DOCBOOK_COLLECTION
  })

  it('rejects when no DOCBOOK_COLLECTION', async () => {
    const store = useCollectionStore()
    await expect(store.loadFromWindow()).rejects.toThrow('No DOCBOOK_COLLECTION found')
  })

  it('selects a book and sets isReading', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test',
      books: [
        { id: 'b1', title: 'Book One', source: '/b1.json' },
      ],
    })
    store.selectBook('b1')
    expect(store.currentBookId).toBe('b1')
    expect(store.isReading).toBe(true)
  })

  it('closes book and resets state', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test',
      books: [{ id: 'b1', title: 'Book One', source: '/b1.json' }],
    })
    store.selectBook('b1')
    store.closeBook()
    expect(store.currentBookId).toBeNull()
    expect(store.isReading).toBe(false)
  })

  it('computes currentBook', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test',
      books: [
        { id: 'b1', title: 'Book One', source: '/b1.json' },
        { id: 'b2', title: 'Book Two', source: '/b2.json' },
      ],
    })
    expect(store.currentBook).toBeNull()
    store.selectBook('b2')
    expect(store.currentBook?.title).toBe('Book Two')
  })

  it('sorts books by lastRead then title', () => {
    const store = useCollectionStore()
    const now = new Date()
    store.loadCollection({
      name: 'Test',
      books: [
        { id: 'b1', title: 'Alpha', source: '/b1.json' },
        { id: 'b2', title: 'Zulu', source: '/b2.json', lastRead: now },
        { id: 'b3', title: 'Bravo', source: '/b3.json' },
      ],
    })
    const sorted = store.sortedBooks
    expect(sorted[0].id).toBe('b2')   // recently read first
    expect(sorted[1].id).toBe('b1')   // then alphabetical
    expect(sorted[2].id).toBe('b3')
  })

  it('sets book progress', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test',
      books: [{ id: 'b1', title: 'Book One', source: '/b1.json' }],
    })
    store.setProgress('b1', 50)
    expect(store.books[0].progress).toBe(50)
  })

  it('clamps progress to 0-100', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test',
      books: [{ id: 'b1', title: 'Book One', source: '/b1.json' }],
    })
    store.setProgress('b1', 150)
    expect(store.books[0].progress).toBe(100)
    store.setProgress('b1', -10)
    expect(store.books[0].progress).toBe(0)
  })

  it('updates lastRead when selecting a book', () => {
    const store = useCollectionStore()
    store.loadCollection({
      name: 'Test',
      books: [{ id: 'b1', title: 'Book One', source: '/b1.json' }],
    })
    expect(store.books[0].lastRead).toBeUndefined()
    store.selectBook('b1')
    expect(store.books[0].lastRead).toBeInstanceOf(Date)
  })
})
