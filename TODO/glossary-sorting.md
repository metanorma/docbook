# R5 — Glossary alphabetical sorting

**Tier:** 2 (small-medium)

## Problem

XSLT stylesheets sort glossary entries alphabetically. The current implementation renders glossary entries in document order. For large glossaries, alphabetical ordering is much more useful for readers.

## What To Do

1. **In `GlossaryService` or transformer** — sort `<glossentry>` elements alphabetically by `<glossterm>` text
2. **Make it optional** — preserve document order by default, add a `sort_glossary` option
3. **CLI flag** — `docbook build --sort-glossary`

## Files

- `lib/docbook/mirror/transformer.rb` — glossary section handling
- Possibly new `lib/docbook/services/glossary_service.rb`

## Verification

Build a DocBook fixture with an unsorted glossary and verify alphabetical ordering when the option is enabled.
