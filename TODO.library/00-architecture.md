# 00 — Architecture: Output Format System

## Problem

The docbook gem currently has a single output path: `SinglePage` produces one self-contained HTML file with all data embedded as `window.DOCBOOK_DATA` JSON. There is no abstraction for different output formats, no library/collection builder, no SEO-friendly output, and no way to split content across pages.

## Design Principles

### Model-Driven Architecture
Data models define the contracts between layers. The mirror node tree is the content model. The collection manifest (Lutaml::Model) is the library model. Format classes consume models — they don't parse raw data.

### Open/Closed Principle (OCP)
- `Pipeline` is closed for modification — its data processing steps are stable
- Format classes are open for extension — add `EpubFormat`, `PdfFormat`, etc. by creating a new class in `formats/` with no changes to `Builder`
- `HtmlRenderer` is open for extension — add new node type renderers without modifying existing ones (dispatch table pattern)

### Encapsulation
- Each format class owns its file structure, HTML template, and data embedding strategy
- `Pipeline` hides the 9-step processing details behind a single `.process()` method
- `HtmlRenderer` hides the node-to-HTML mapping behind a single `.render()` method
- `CollectionManifest` service hides directory scanning, YAML parsing, and path resolution

### Single Responsibility
- `Pipeline`: transform XML to processed data
- `HtmlRenderer`: transform mirror node tree to HTML string
- `Format::*`: package data into a specific output structure
- `Builder`: orchestrate Pipeline + Format for a single book
- `LibraryBuilder`: orchestrate Pipeline + Format for a collection
- `CollectionManifest`: parse and resolve manifest data

## Class Diagram

```
Pipeline
  .process(xml_path, **) → Hash (guide)

HtmlRenderer
  .new(guide) → HtmlRenderer
  #render → String (HTML)

Format::BaseFormat (abstract)
  #write(output_path, guide, manifest: nil) → void
  #write_library(output_path, guides, manifest:) → void

Format::InlineFormat < BaseFormat    # single HTML, JSON in window global
Format::DomFormat < BaseFormat       # single HTML, content in DOM + JSON
Format::DistFormat < BaseFormat      # directory, external JSON files
Format::PagedFormat < BaseFormat     # directory, per-page HTML

Builder
  #build → output_path
  delegates to Pipeline.process → Format.write

LibraryBuilder
  #build → output_path
  delegates to CollectionManifest.parse → Pipeline.process (per book) → Format.write_library

Models::BookEntry (Lutaml::Model, json do)
Models::CollectionManifest (Lutaml::Model, json do)

Services::CollectionManifest
  .parse(input_path) → Models::CollectionManifest (with resolved paths)
```

## Four Output Formats (MECE)

| Format | Packaging | Content Embedding | SEO | Vue Loader | Use Case |
|--------|-----------|-------------------|-----|------------|----------|
| `inline` | 1 file | `window.DOCBOOK_DATA` JSON | No | InlineJsonLoader | Offline, email, small docs |
| `dom` | 1 file | HTML in `<div id="docbook-content">` + JSON | Yes | DomContentLoader | Public websites, SEO |
| `dist` | Directory | Separate `.json` files | No | ExternalJsonLoader | Large books, CDN hosting |
| `paged` | Directory | One `.html` per chapter/section | Yes | PagedLoader | Large books, deep SEO |

## Data Flow

```
Single Book:
  XML → Pipeline.process → guide hash → Format.write → output

Library:
  Directory/Manifest → CollectionManifest.parse → manifest
    for each book: Pipeline.process → guide hash
  → [guide1, guide2, ...] → Format.write_library → output
```

## CLI Surface

Both commands share the same format and processing options:

```
docbook build INPUT --format inline|dom|dist|paged [options]
docbook library INPUT --format inline|dom|dist|paged [options]
```

Options (shared):
- `-o, --output PATH` — output file or directory
- `--title TITLE` — page/library title
- `--image-strategy data_url|file_url|relative`
- `--sort-glossary`
- `--verbose` / `--quiet`
