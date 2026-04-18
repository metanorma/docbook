# TODO — Remaining Work

Consolidated from previous TODO files. Completed items have been removed.

## Priority Tiers

### Tier 1: Docs fixes (small, high value)
- [x] [D1](docs-fixes.md) — Fix duplicate INDEX.adoc entry, document `--demo=NAME`, audit stale refs

### Tier 2: Ruby gem (medium)
- [x] [R1](yard-api-docs.md) — YARD API documentation
- [x] [R2](annotation-popups.md) — Annotation hover popups in Vue frontend
- [x] [R3](callout-markers.md) — Callout markers for code blocks
- [x] [R4](qandaset-processing.md) — Q&A set processing
- [x] [R5](glossary-sorting.md) — Glossary alphabetical sorting

### Tier 3: Frontend performance (large)
- [x] [F1](performance-large-docs.md) — Deferred section rendering, lazy search indexing

### Tier 4: Ebook UX (nice-to-have)
- [x] [E1](ebook-paginated-mode.md) — Single page / paginated reading
- [x] [E2](ebook-card-swipe.md) — Reference card swipe mode
- [x] [E3](ebook-reading-ruler.md) — Reading ruler
- [x] [E4](ebook-bookmarks.md) — Bookmarks
- [x] [E5](ebook-tts.md) — TTS with highlighting
- [x] [E6](ebook-stats.md) — Reading statistics
- [x] [E7](ebook-cloud-sync.md) — Cloud sync

## All items verified and implemented (2026-04-18)

All TODO items have been audited and verified as implemented with:
- Correct OOP/OCP/SRP architecture
- Ruby transformer specs (652 examples, 0 failures)
- Vue composable integration in App.vue
- Comprehensive documentation

## Previously completed (removed from tracking)

These were found already implemented during earlier audits:
- Full-text body search (SearchModal.vue)
- External link handling (TextRenderer.vue)
- CHANGELOG update (CHANGELOG.md)
- XSLT migration guide (docs/guides/migrating-from-xslt.adoc)
- Settings panel overhaul (SettingsPanel.vue)
- DocbookMirror architecture refactor (complete)
