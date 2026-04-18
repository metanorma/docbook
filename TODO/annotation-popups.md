# R2 — Annotation hover popups

**Tier:** 2 (medium)

## Problem

DocBook `<annotation>` elements provide explanatory notes. The transformer processes them (via `annotation_node` in `transformer.rb:940`), but the Vue frontend renders them as plain inline content with no interactive popup UI. XSLT typically renders annotations as hover popups or footnotes.

## What To Do

1. **In the transformer** — ensure annotation marks carry enough data (annotation id, reference text)
2. **In TextRenderer.vue** — render annotation markers as a clickable/hoverable inline element
3. **New component** — `AnnotationPopup.vue` that shows on hover/click with the annotation body text
4. **Positioning** — use floating-ui or simple absolute positioning near the marker

## Files

- `lib/docbook/mirror/transformer.rb` — `annotation_node` method
- `frontend/src/components/TextRenderer.vue` — annotation mark rendering
- `frontend/src/components/AnnotationPopup.vue` — new popup component

## Verification

Build a DocBook fixture with `<annotation>` elements and verify hover popups appear.
