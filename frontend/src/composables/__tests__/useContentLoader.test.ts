import { describe, it, expect, beforeEach } from 'vitest'
import { createContentLoader, getOutputFormat, isDomFormat } from '../useContentLoader'

describe('useContentLoader', () => {
  const originalWindow = { ...globalThis.window }

  beforeEach(() => {
    // Reset window globals
    const w = globalThis as any
    delete w.DOCBOOK_FORMAT
    delete w.DOCBOOK_DATA
    delete w.DOCBOOK_DATA_SOURCE
  })

  describe('InlineJsonLoader', () => {
    it('returns null when no DOCBOOK_DATA', async () => {
      const loader = createContentLoader()
      const data = await loader.load()
      expect(data).toBeNull()
    })

    it('returns DOCBOOK_DATA when present', async () => {
      const testData = { title: 'Test', content: [] }
      ;(globalThis as any).DOCBOOK_DATA = testData
      const loader = createContentLoader()
      const data = await loader.load()
      expect(data).toEqual(testData)
    })
  })

  describe('ExternalJsonLoader', () => {
    it('is selected when DOCBOOK_FORMAT is dist', () => {
      ;(globalThis as any).DOCBOOK_FORMAT = 'dist'
      const loader = createContentLoader()
      // ExternalJsonLoader has different behavior (fetch)
      expect(loader.constructor.name).toBe('ExternalJsonLoader')
    })
  })

  describe('getOutputFormat', () => {
    it('returns inline by default', () => {
      expect(getOutputFormat()).toBe('inline')
    })

    it('returns dist when set', () => {
      ;(globalThis as any).DOCBOOK_FORMAT = 'dist'
      expect(getOutputFormat()).toBe('dist')
    })
  })

  describe('isDomFormat', () => {
    it('returns false by default', () => {
      expect(isDomFormat()).toBe(false)
    })

    it('returns true when format is dom', () => {
      ;(globalThis as any).DOCBOOK_FORMAT = 'dom'
      expect(isDomFormat()).toBe(true)
    })
  })
})
