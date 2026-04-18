# F1 — Performance & lazy rendering for large documents

**Tier:** 3 (large)

## Problem

The reader renders the **entire document** on mount. For large technical references (500+ pages, 200+ sections), the JSON payload could exceed 5MB and the DOM would contain thousands of nodes.

Current architecture:
1. `documentStore.loadFromWindow()` loads the entire JSON into a reactive `ref`
2. `MirrorRenderer` recursively renders **all blocks** immediately
3. Vue tracks reactivity on every node in the document tree
4. No lazy loading, no virtual scrolling, no section deferral

## What To Do

### Phase 1: Deferred section rendering
1. Use `IntersectionObserver` to detect when sections approach the viewport
2. Render a placeholder (div with estimated height) for non-visible sections
3. Only render actual content when section is near viewport (`rootMargin: '2000px'`)

### Phase 2: Lazy search indexing
1. Index section headings immediately (fast, small)
2. Background-index body text via `requestIdleCallback` or web worker
3. Show "indexing..." status for body search until complete

### Phase 3: Memory management
1. Remove DOM nodes for sections far out of viewport
2. Keep ProseMirror JSON in memory (cheap) but don't render to DOM until needed
3. `shallowRef` for document data to avoid deep reactivity (partially done)

## Files

- `frontend/src/components/MirrorRenderer.vue` — deferred rendering
- `frontend/src/stores/documentStore.ts` — `shallowRef` optimization
- New `frontend/src/composables/useLazySections.ts` — IntersectionObserver logic
- `frontend/src/components/SearchModal.vue` — lazy index building

## Acceptance Criteria

- Initial render time under 500ms for a 200-section document
- Sections render on-demand as the reader scrolls
- Scroll position is preserved when sections are added/removed
- Memory usage stays constant regardless of document length
- Search index builds progressively without blocking the UI
