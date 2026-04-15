import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface BookMeta {
  id: string
  title: string
  author?: string
  description?: string
  cover?: string
  source: string // URL or path to docbook.data.json
  lastRead?: Date
  progress?: number // 0-100
}

export interface CollectionData {
  name: string
  description?: string
  books: BookMeta[]
}

export const useCollectionStore = defineStore('collection', () => {
  const books = ref<BookMeta[]>([])
  const collectionName = ref('My Library')
  const currentBookId = ref<string | null>(null)
  const isReading = ref(false)
  const isLoading = ref(false)

  const currentBook = computed(() =>
    books.value.find(b => b.id === currentBookId.value) || null
  )

  const sortedBooks = computed(() =>
    [...books.value].sort((a, b) => {
      // Recently read first, then by title
      if (a.lastRead && b.lastRead) return b.lastRead.getTime() - a.lastRead.getTime()
      if (a.lastRead) return -1
      if (b.lastRead) return 1
      return a.title.localeCompare(b.title)
    })
  )

  function loadCollection(data: CollectionData) {
    collectionName.value = data.name || 'My Library'
    books.value = data.books.map(book => ({
      ...book,
      lastRead: book.lastRead ? new Date(book.lastRead) : undefined
    }))
  }

  function loadFromWindow(): Promise<void> {
    const data = (window as any).DOCBOOK_COLLECTION
    if (data) {
      loadCollection(data)
      return Promise.resolve()
    }
    return Promise.reject(new Error('No DOCBOOK_COLLECTION found'))
  }

  function selectBook(bookId: string) {
    currentBookId.value = bookId
    isReading.value = true

    // Update last read
    const book = books.value.find(b => b.id === bookId)
    if (book) {
      book.lastRead = new Date()
    }
  }

  function closeBook() {
    isReading.value = false
    currentBookId.value = null
  }

  function setProgress(bookId: string, progress: number) {
    const book = books.value.find(b => b.id === bookId)
    if (book) {
      book.progress = Math.min(100, Math.max(0, progress))
    }
  }

  return {
    books,
    collectionName,
    currentBookId,
    currentBook,
    sortedBooks,
    isReading,
    isLoading,
    loadCollection,
    loadFromWindow,
    selectBook,
    closeBook,
    setProgress
  }
})
