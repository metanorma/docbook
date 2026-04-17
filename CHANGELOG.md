## [Unreleased]

### Added

- CLI: `docbook info` command for document metadata and statistics (plain text or `--json`)
- CLI: `docbook version` (or `--version` / `-v`) to show gem version
- Copy-to-clipboard button on code blocks (with file:// fallback)
- Section anchor links (permalink `#` on hover)
- Image lightbox (click to zoom)
- Keyboard navigation: `j`/`k` for section-to-section, `/` for search, `Esc` to close
- Keyboard shortcuts: `s` for settings, `f` for focus mode, `t` for sidebar, `?` for help overlay
- FlexSearch full-text search
- Settings panel redesigned as right-side sliding panel with new controls: line height, text alignment, hyphenation, focus mode, progress bar toggle
- Reading progress bar at top of viewport
- Focus/immersive reading mode: hides chrome for distraction-free reading
- Section prev/next navigation arrows at bottom of viewport
- Code block polish: language badge on hover, accent left border, improved monospace font
- Admonition redesign: SVG icons for note/warning/danger/caution/important/tip with flex layout
- Table horizontal scroll with sticky headers and zebra striping
- Back-to-top floating button
- Print stylesheet: hides all chrome for clean print/PDF output
- Mobile responsive: compact top bar, full-screen settings, touch-friendly targets
- Generated lists of figures, tables, and examples in the reader
- Footnote processing: numbered superscript markers with end-of-section collected notes
- Annotation rendering: styled callout blocks for DocBook annotation elements
- Jekyll documentation site (59 pages)
- YARD API documentation configuration
- XSLT migration guide

### Changed

- `--demo` option changed from boolean to string, accepting `xslTNG` (default) or `model-flow`
- Content width presets adjusted for more dramatic visual change: 38rem / 58rem / 82rem
- CLI error messages are now colored and more helpful
- Output directories are auto-created when specified via `-o`

## [0.1.0] - 2026-04-05

### Added

- CLI: `build`, `export`, `validate`, `format`, `roundtrip` commands
- `build --demo` with named demo selection (`xslTNG`, `model-flow`)
- Interactive HTML reader (self-contained, works offline via file://)
- Vue 3 SPA frontend with MirrorRenderer and TextRenderer components
- 4 reading themes: Day, Sepia, Night, OLED
- Settings panel with theme, font size, typeface (sans/serif), and content width controls
- Copy-to-clipboard button on code blocks
- Section anchor links (permalink `#` on hover)
- Image lightbox (click to zoom)
- Keyboard navigation: `j`/`k` for section-to-section, `/` for search, `Esc` to close
- FlexSearch full-text search
- Collapsible hierarchical TOC navigation
- Breadcrumb bar with section ancestor chain
- DocbookMirror JSON export (ProseMirror-compatible format)
- Mirror::Transformer bidirectional DocBook <-> DocbookMirror conversion
- 170+ DocBook 5 element classes via lutaml-model
- XInclude resolution (XML, text, text+fragid with search=/line=/char=)
- Cross-reference resolution (xref -> section titles)
- RELAX NG schema validation (auto-detects XInclude schema)
- Image resolution with 3 strategies: data_url, file_url, relative
- Section numbering (Roman numerals, hierarchical A.1, 1.2.3)
- Index generation from indexterm elements
- Reference Entry (refentry) card-style rendering
- DocBook XML formatting/prettifying
- Round-trip testing (XML -> parse -> serialize -> parse)
- 567 passing specs
- Jekyll documentation site (59 pages)
- "Art of the Model Flow" demo document

### Changed

- `--demo` option changed from boolean to string, accepting `xslTNG` (default) or `model-flow`
- Settings panel redesigned: removed non-functional Reading Mode, added Typeface and Content Width controls
- Image resolution now derives search paths from XML file location, with warning for unresolved images
