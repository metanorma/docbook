// Content loader abstraction for four output formats:
// inline, dom, dist, paged
//
// Each loader hides its data source (window global, fetch, DOM)
// behind the same interface. The documentStore doesn't know where data comes from.

export interface ContentLoader {
  load(): Promise<Record<string, any> | null>
}

// Factory — returns the correct loader based on window globals
export function createContentLoader(): ContentLoader {
  const w = window as any
  const format = w.DOCBOOK_FORMAT

  if (format === 'dist') return new ExternalJsonLoader()
  // dom, paged, and default all use inline data
  return new InlineJsonLoader()
}

// 1. Inline JSON — reads window.DOCBOOK_DATA (current behavior)
class InlineJsonLoader implements ContentLoader {
  async load(): Promise<Record<string, any> | null> {
    const data = (window as any).DOCBOOK_DATA
    return data || null
  }
}

// 2. External JSON — fetches from URL in window.DOCBOOK_DATA_SOURCE
class ExternalJsonLoader implements ContentLoader {
  async load(): Promise<Record<string, any> | null> {
    const source = (window as any).DOCBOOK_DATA_SOURCE
    if (!source) return null
    try {
      const res = await fetch(source)
      return res.ok ? await res.json() : null
    } catch {
      return null
    }
  }
}

// Format detection helpers
export function getOutputFormat(): string {
  return (window as any).DOCBOOK_FORMAT || 'inline'
}

export function isDomFormat(): boolean {
  return getOutputFormat() === 'dom'
}
