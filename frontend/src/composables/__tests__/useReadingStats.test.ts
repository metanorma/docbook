import { describe, it, expect, beforeEach, vi } from 'vitest'

// Mock Vue lifecycle hooks to avoid DOM dependency
vi.mock('vue', async (importOriginal) => {
  const mod = await importOriginal<typeof import('vue')>()
  return {
    ...mod,
    onMounted: vi.fn((fn: () => void) => fn()),
    onUnmounted: vi.fn(),
  }
})

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
  configurable: true,
})

describe('useReadingStats', () => {
  let useReadingStats: typeof import('../useReadingStats')['useReadingStats']

  beforeEach(async () => {
    const mod = await import('../useReadingStats')
    useReadingStats = mod.useReadingStats
  })

  it('initializes with zero sections read', () => {
    const stats = useReadingStats('Test Book', 5, ['s1', 's2', 's3', 's4', 's5'])
    expect(stats.sectionsReadCount.value).toBe(0)
    expect(stats.readPercentage.value).toBe(0)
  })

  it('tracks sections read', () => {
    const stats = useReadingStats('Test Book', 5, ['s1', 's2', 's3', 's4', 's5'])
    stats.markSectionRead('s1')
    expect(stats.sectionsReadCount.value).toBe(1)
    stats.markSectionRead('s2')
    expect(stats.sectionsReadCount.value).toBe(2)
    expect(stats.readPercentage.value).toBe(40)
  })

  it('does not double-count sections', () => {
    const stats = useReadingStats('Test Book', 3, ['s1', 's2', 's3'])
    stats.markSectionRead('s1')
    stats.markSectionRead('s1')
    expect(stats.sectionsReadCount.value).toBe(1)
  })

  it('checks if a section is read', () => {
    const stats = useReadingStats('Test Book', 2, ['s1', 's2'])
    expect(stats.isSectionRead('s1')).toBe(false)
    stats.markSectionRead('s1')
    expect(stats.isSectionRead('s1')).toBe(true)
  })

  it('records activity within timeout window', () => {
    const stats = useReadingStats('Test Book', 1, ['s1'])
    stats.recordActivity()
    const before = stats.activeReadingMinutes.value
    stats.recordActivity()
    expect(stats.activeReadingMinutes.value).toBeGreaterThanOrEqual(before)
  })

  it('tracks read percentage', () => {
    const stats = useReadingStats('Test Book', 4, ['s1', 's2', 's3', 's4'])
    stats.markSectionRead('s1')
    stats.markSectionRead('s2')
    expect(stats.readPercentage.value).toBe(50)
  })

  it('handles zero totalSections', () => {
    const stats = useReadingStats('Empty', 0, [])
    expect(stats.readPercentage.value).toBe(0)
  })
})
