# 08 — Vue Frontend Content Loader

## Goal

Abstract content loading in the Vue SPA to support four modes: inline JSON, external JSON, DOM hydration, and paged navigation. The frontend must detect which mode is in use and load content accordingly.

## Design

### OCP Compliance
Each content loader is a self-contained composable. Adding a new loading mode means adding a new loader — existing loaders and the documentStore are unchanged.

### Encapsulation
Each loader hides its data source (window global, fetch, DOM) behind the same interface. The documentStore doesn't know where data comes from.

### Model-Driven
All loaders produce the same output: a guide hash that populates `documentStore`. The data model is the contract.

## Files

### New: `frontend/src/composables/useContentLoader.ts`

```typescript
// Content loader interface — all loaders implement this
export interface ContentLoader {
  load(): Promise<GuideData | null>
}

// Guide data = the same structure as window.DOCBOOK_DATA
export interface GuideData {
  type: 'doc'
  attrs: { title: string }
  content: any[]
  toc: { sections: any[]; numbering: Record<string, string> }
  index: any
  meta: Record<string, any>
  [key: string]: any
}

// Factory — returns the correct loader based on window globals
export function createContentLoader(): ContentLoader {
  const format = (window as any).DOCBOOK_FORMAT

  if (format === 'dom') return new DomContentLoader()
  if (format === 'dist') return new ExternalJsonLoader()
  if (format === 'paged') return new PagedLoader()
  // Default: inline (current behavior)
  return new InlineJsonLoader()
}

// --- Loader implementations ---

// 1. Inline JSON — reads window.DOCBOOK_DATA (current behavior, extracted)
class InlineJsonLoader implements ContentLoader {
  async load(): Promise<GuideData | null> {
    const data = (window as any).DOCBOOK_DATA
    return data || null
  }
}

// 2. External JSON — fetches from URL in window.DOCBOOK_DATA_SOURCE
class ExternalJsonLoader implements ContentLoader {
  async load(): Promise<GuideData | null> {
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

// 3. DOM Content — content is pre-rendered in #docbook-content
//    Vue hydrates it — reads from DOM instead of rendering from JSON
class DomContentLoader implements ContentLoader {
  async load(): Promise<GuideData | null> {
    // JSON is still present for TOC, search, themes
    return (window as any).DOCBOOK_DATA || null
  }
}

// 4. Paged — loads per-page content, handles navigation
class PagedLoader implements ContentLoader {
  async load(): Promise<GuideData | null> {
    // For the index page, load TOC metadata
    // For content pages, fetch the page's JSON
    const pageId = (window as any).DOCBOOK_PAGE_ID
    if (pageId) {
      // We're on a content page — data is embedded
      return (window as any).DOCBOOK_DATA || null
    }
    // We're on the index — just load TOC for navigation
    return null
  }
}
```

### Modify: `frontend/src/stores/documentStore.ts`

Add loading methods that delegate to the content loader:

```typescript
import { createContentLoader } from '@/composables/useContentLoader'

// In the store setup:
const loader = createContentLoader()

// Replace loadFromWindow internals:
async function loadContent(): Promise<void> {
  const data = await loader.load()
  if (data) {
    processDocbookData(data)
  }
}

// Keep loadFromWindow for backward compatibility — it now delegates
function loadFromWindow(): Promise<void> {
  return loadContent()
}
```

### Modify: `frontend/src/components/library/CollectionReader.vue`

Line 82 — relax source URL check to allow relative paths:

```typescript
// Before:
if (book.source && (book.source.startsWith('http') || book.source.startsWith('/')))

// After:
if (book.source)
```

### Modify: `frontend/src/App.vue`

For DOM format, the content is already in `#docbook-content`. The Vue app should:
- Read `window.DOCBOOK_FORMAT`
- If `'dom'`: skip MirrorRenderer, let the pre-rendered HTML stand. Vue adds TOC, search, themes on top.
- Otherwise: render from JSON as before (current behavior)

```typescript
// In the template or setup:
const format = (window as any).DOCBOOK_FORMAT
const hasDomContent = format === 'dom' && document.getElementById('docbook-content')

// If hasDomContent, the MirrorRenderer is not needed — content is already rendered
// Vue still provides: TOC sidebar, search, theme switcher, etc.
```

### Modify: `frontend/src/app.ts`

The app entry already branches on `window.DOCBOOK_COLLECTION`. No changes needed for the basic detection — the format is communicated via `window.DOCBOOK_FORMAT` which the components read.

## Data Flow by Format

### Inline (current)
```
HTML loads → window.DOCBOOK_DATA set → InlineJsonLoader.load() → processDocbookData → MirrorRenderer
```

### DOM
```
HTML loads → #docbook-content has HTML → window.DOCBOOK_DATA also set → DomContentLoader.load() → processDocbookData (for TOC/search)
Content already visible in DOM (SEO). Vue hydrates: adds TOC sidebar, themes.
```

### Dist
```
HTML loads → window.DOCBOOK_DATA_SOURCE = "data/book.json" → ExternalJsonLoader.load() → fetch → processDocbookData → MirrorRenderer
```

### Paged
```
Index page: TOC + navigation rendered by Vue
Content pages: each is standalone HTML with its section's content pre-rendered + JSON for interactivity
Navigation: standard <a href> links between pages
```

## Verification

1. `--format inline` — loads from `window.DOCBOOK_DATA` correctly
2. `--format dom` — page shows content even with JavaScript disabled
3. `--format dist` — book data loaded from separate JSON file
4. `--format paged` — navigation between chapter pages works
5. `npm run build` — Vue app builds successfully
6. All existing Vue tests pass
