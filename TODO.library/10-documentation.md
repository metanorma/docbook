# 10 — Publisher Documentation

## Goal

Write publisher-facing documentation covering book organization, collection manifests, output formats, and CLI usage.

## Files

### New: `docs/guides/organizing-book.adoc`

Documents how to organize a single DocBook book project:

**Contents:**
- Recommended folder structure
- Cover image conventions (`cover.png` etc.)
- DocBook XML `<info>` metadata fields
- DocBook `<cover>` element for cover images
- CLI usage: `docbook build book.xml --format inline|dom|dist|paged`
- Ruby API: `Docbook::Output::Builder`

**Folder structure example:**
```
my-book/
  book.xml              # DocBook 5 XML (required)
  cover.png             # Cover image (optional, convention)
  media/                # Images referenced from XML
    figure1.png
    screenshot.jpg
  chapters/             # XIncludes (optional)
    ch01.xml
    ch02.xml
```

### New: `docs/guides/building-library.adoc`

Documents how to organize and build a multi-book library:

**Contents:**
- Directory auto-discovery mode
- Manifest file mode (YAML and JSON)
- Complete manifest schema table
- Cover resolution priority
- CLI usage: `docbook library INPUT --format inline|dom|dist|paged`
- Ruby API: `Docbook::Output::LibraryBuilder`

**Directory structure (auto-discovery):**
```
my-library/
  book-one/
    book-one.xml
    cover.png
    media/
  book-two/
    book-two.xml
    cover.svg
```

**Manifest (YAML):**
```yaml
name: "My Technical Library"
description: "A curated collection of DocBook publications"
books:
  - id: "user-guide"
    source: "user-guide/guide.xml"
    title: "User Guide v3.0"
    cover: "user-guide/cover.png"
  - id: "api-reference"
    source: "api/api-ref.xml"
```

### New: `docs/interfaces/cli/library-command.adoc`

CLI reference for `docbook library`:

**Contents:**
- Command syntax
- All options with descriptions
- Examples for each format
- Input types (directory, YAML manifest, JSON manifest)
- Output structure for each format

### New: `docs/features/output-formats.adoc`

Explains the four output formats and when to use each:

**Contents:**

== Output Formats

The docbook gem supports four output formats, selected via `--format`:

=== inline (default)

Single self-contained HTML file. All CSS, JavaScript, and book data inlined.

- Works from `file://` protocol (offline, email attachments)
- No server required
- Large file size for big books
- No SEO (content is JSON, not visible to search engines)

=== dom

Single HTML file with content pre-rendered in the DOM. Same as inline but content is also embedded as HTML.

- Works from `file://` protocol
- Content visible to search engines
- Larger file size than inline (HTML + JSON)

=== dist (distribution)

Directory with separate files: `index.html` + `data/*.json`.

- Book data loaded on demand (better for large books)
- Requires HTTP server (not `file://` compatible)
- CDN-friendly (static files)
- No SEO

=== paged (split pages)

Directory with one HTML file per chapter/section.

- Best SEO (every page is indexable)
- Natural pagination (no full-book load)
- Requires HTTP server
- Deep linking to specific chapters

=== Format Comparison

[cols="1,1,1,1,1"]
|===
| | inline | dom | dist | paged

| Output
| 1 file
| 1 file
| directory
| directory

| SEO
| No
| Yes
| No
| Yes

| file://
| Yes
| Yes
| No
| No

| Incremental load
| No
| No
| Yes
| Yes

| Large books
| Slow initial
| Slow initial
| Fast
| Fast
|===

### Modify: `docs/INDEX.adoc`

Add to Quick Navigation:
- "Build a library" → link to building-library guide
- "Choose output format" → link to output-formats feature

Add to Learning Path.

### Modify: `docs/guides/index.adoc`

Add entries for:
- Organizing a Book
- Building a Library

### Modify: `docs/interfaces/cli/index.adoc`

Add link to library-command reference.

### Modify: `docs/interfaces/cli/build-command.adoc` (existing)

Add `--format` option documentation.

## Verification

1. Jekyll builds the docs site without errors
2. All internal links resolve
3. Code examples are accurate (match actual CLI output)
4. Schema tables match the Lutaml::Model definitions
