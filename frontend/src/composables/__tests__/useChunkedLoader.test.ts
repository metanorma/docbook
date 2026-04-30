import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useChunkedLoader } from '@/composables/useChunkedLoader'

describe('useChunkedLoader', () => {
  let loader: ReturnType<typeof useChunkedLoader>

  beforeEach(() => {
    loader = useChunkedLoader()
    loader.reset()
  })

  describe('initial state', () => {
    it('starts with no manifest', () => {
      expect(loader.manifest.value).toBeNull()
    })

    it('starts with no loaded sections', () => {
      expect(loader.loadedIds.value.size).toBe(0)
    })

    it('starts with content not fully loaded', () => {
      expect(loader.allContentLoaded.value).toBe(false)
    })

    it('returns empty content when no manifest', () => {
      expect(loader.getAssembledContent()).toEqual([])
    })
  })

  describe('loadManifest', () => {
    it('fetches manifest from default URL', async () => {
      const mockManifest = {
        meta: { title: 'Test' },
        toc: { sections: [], numbering: {} },
        total_sections: 0,
        section_ids: [],
      }
      const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockManifest),
      } as Response)

      const result = await loader.loadManifest()
      expect(result.meta.title).toBe('Test')
      expect(result.total_sections).toBe(0)
      expect(fetchSpy).toHaveBeenCalledWith('manifest.json')

      fetchSpy.mockRestore()
    })

    it('uses DOCBOOK_MANIFEST window global', async () => {
      ;(window as any).DOCBOOK_MANIFEST = 'custom/manifest.json'
      const mockManifest = {
        meta: {},
        toc: {},
        total_sections: 0,
        section_ids: [],
      }
      const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockManifest),
      } as Response)

      await loader.loadManifest()
      expect(fetchSpy).toHaveBeenCalledWith('custom/manifest.json')

      delete (window as any).DOCBOOK_MANIFEST
      fetchSpy.mockRestore()
    })

    it('throws on failed fetch', async () => {
      const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue({
        ok: false,
        status: 404,
      } as Response)

      await expect(loader.loadManifest()).rejects.toThrow('Failed to load manifest')
      fetchSpy.mockRestore()
    })
  })

  describe('loadSection', () => {
    it('loads section from network', async () => {
      // Set up manifest first
      const mockManifest = {
        meta: {},
        toc: {},
        total_sections: 2,
        section_ids: ['sec1', 'sec2'],
      }
      vi.spyOn(globalThis, 'fetch')
        .mockResolvedValueOnce({ ok: true, json: () => Promise.resolve(mockManifest) } as Response)
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ id: 'sec1', content: [{ type: 'paragraph' }], next: 'sec2', prev: null }),
        } as Response)

      await loader.loadManifest()
      const data = await loader.loadSection('sec1', false)
      expect(data?.id).toBe('sec1')
      expect(loader.loadedIds.value.has('sec1')).toBe(true)
      vi.restoreAllMocks()
    })

    it('returns null for empty section id', async () => {
      const result = await loader.loadSection('')
      expect(result).toBeNull()
    })
  })

  describe('reset', () => {
    it('clears all state', async () => {
      const mockManifest = {
        meta: { title: 'Test' },
        toc: {},
        total_sections: 0,
        section_ids: [],
      }
      vi.spyOn(globalThis, 'fetch').mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockManifest),
      } as Response)

      await loader.loadManifest()
      expect(loader.manifest.value).not.toBeNull()

      loader.reset()
      expect(loader.manifest.value).toBeNull()
      expect(loader.loadedIds.value.size).toBe(0)
      vi.restoreAllMocks()
    })
  })
})
