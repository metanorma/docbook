# 04 — Format Classes

## Goal

Implement four format strategy classes that package processed book data into specific output structures. All formats share the same input (guide hash from Pipeline) but differ in how they embed content and structure files.

## Design

### OCP Compliance
Each format is a self-contained class. Adding a new format (e.g., `EpubFormat`) means creating a new file — no modification to `Builder`, `Pipeline`, or other formats.

### Encapsulation
Each format owns:
- Its HTML template structure
- How data is embedded (window global, DOM, external files)
- File structure (single file vs directory)
- What window globals are set for the Vue app

### Inheritance
`BaseFormat` provides shared utilities (reading dist assets, HTML boilerplate, JSON escaping). Format subclasses override only what's different.

## Files

### New: `lib/docbook/output/formats/base_format.rb`

```ruby
module Docbook
  module Output
    module Formats
      class BaseFormat
        FRONTEND_DIST = File.expand_path("../../../../frontend/dist", __dir__)

        attr_reader :dist_dir

        def initialize(dist_dir: nil)
          @dist_dir = dist_dir || FRONTEND_DIST
        end

        # Write a single book output
        def write(output_path, guide, title: "DocBook", manifest: nil)
          raise NotImplementedError, "#{self.class}#write not implemented"
        end

        # Write a library output (multiple books)
        def write_library(output_path, guides, manifest:, title: nil)
          raise NotImplementedError, "#{self.class}#write_library not implemented"
        end

        protected

        def dist_assets
          {
            css: File.read(File.join(@dist_dir, "app.css")),
            js: File.read(File.join(@dist_dir, "app.iife.js")),
          }
        end

        def safe_json(data)
          JSON.generate(data).gsub("</script", '<\\/script')
        end

        def html_boilerplate(title:, head_extra: "", body_content:, script_data: nil)
          assets = dist_assets
          data_script = script_data ? %(<script>#{script_data}</script>) : ""

          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>#{title}</title>
              <style>#{assets[:css]}</style>
              #{data_script}
              #{head_extra}
            </head>
            <body>
              #{body_content}
              <script>#{assets[:js]}</script>
            </body>
            </html>
          HTML
        end

        def embed_as_data_url(path)
          return nil unless path && File.exist?(path)
          mime = mime_type(path)
          return path unless mime
          data = File.binread(path)
          "data:#{mime};base64,#{Base64.strict_encode64(data)}"
        rescue StandardError
          path
        end

        def mime_type(path)
          case File.extname(path).downcase
          when ".png" then "image/png"
          when ".jpg", ".jpeg" then "image/jpeg"
          when ".gif" then "image/gif"
          when ".svg" then "image/svg+xml"
          when ".webp" then "image/webp"
          end
        end
      end
    end
  end
end
```

### New: `lib/docbook/output/formats/inline_format.rb`

Single HTML file. All data in `window.DOCBOOK_DATA` or `window.DOCBOOK_COLLECTION`.

```ruby
class InlineFormat < BaseFormat
  def write(output_path, guide, title: "DocBook", manifest: nil)
    FileUtils.mkdir_p(File.dirname(output_path))
    data_script = "window.DOCBOOK_DATA = #{safe_json(guide)};"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    File.write(output_path, html)
    output_path
  end

  def write_library(output_path, guides, manifest:, title: nil)
    title ||= manifest.name || "DocBook Library"
    collection_data = build_collection_data(guides, manifest)
    data_script = "window.DOCBOOK_COLLECTION = #{safe_json(collection_data)};"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, html)
    output_path
  end

  private

  def build_collection_data(guides, manifest)
    books = manifest.books.each_with_index.map do |book, i|
      guide = guides[i]
      meta = guide["meta"] || {}
      cover = resolve_cover(book, guide)

      {
        "id" => book.id,
        "title" => book.title || meta["title"] || book.id,
        "author" => book.author || meta["author"],
        "description" => book.description,
        "cover" => cover,
        "source" => "",
        "data" => guide,
      }.compact
    end

    { "name" => manifest.name, "description" => manifest.description, "books" => books }
  end

  def resolve_cover(book_entry, guide)
    # Priority: manifest cover > XML cover element
    if book_entry.cover && File.exist?(book_entry.cover)
      return embed_as_data_url(book_entry.cover)
    end
    xml_cover = guide.dig("meta", "cover")
    if xml_cover
      xml_dir = File.dirname(book_entry.xml_path)
      abs = File.expand_path(xml_cover, xml_dir)
      return embed_as_data_url(abs) if File.exist?(abs)
    end
    nil
  end
end
```

### New: `lib/docbook/output/formats/dom_format.rb`

Single HTML file. Content pre-rendered as HTML in `<div id="docbook-content">` for SEO. JSON also present for Vue interactivity.

```ruby
class DomFormat < BaseFormat
  def write(output_path, guide, title: "DocBook", manifest: nil)
    FileUtils.mkdir_p(File.dirname(output_path))
    renderer = HtmlRenderer.new(guide)
    content_html = renderer.render

    body = <<~HTML
      <div id="docbook-content">#{content_html}</div>
      <div id="docbook-app"></div>
    HTML

    data_script = "window.DOCBOOK_DATA = #{safe_json(guide)}; window.DOCBOOK_FORMAT = 'dom';"
    html = html_boilerplate(title: title, body_content: body, script_data: data_script)
    File.write(output_path, html)
    output_path
  end

  def write_library(output_path, guides, manifest:, title: nil)
    title ||= manifest.name || "DocBook Library"
    collection_data = build_collection_data(guides, manifest)
    data_script = "window.DOCBOOK_COLLECTION = #{safe_json(collection_data)}; window.DOCBOOK_FORMAT = 'dom';"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, html)
    output_path
  end

  private

  # Reuse same collection building logic as InlineFormat
  # (consider extracting to a shared module if it grows)
  def build_collection_data(guides, manifest)
    # ... same as InlineFormat but with "data" always included inline
  end
end
```

### New: `lib/docbook/output/formats/dist_format.rb`

Directory. `index.html` + `data/` with per-book JSON files. Vue fetches data on demand.

```ruby
class DistFormat < BaseFormat
  def write(output_path, guide, title: "DocBook", manifest: nil)
    dir = output_path.end_with?(".html") ? File.dirname(output_path) : output_path
    FileUtils.mkdir_p(dir)
    FileUtils.mkdir_p(File.join(dir, "data"))

    # Write book data as JSON file
    data_filename = "data/book.json"
    File.write(File.join(dir, data_filename), JSON.generate(guide))

    # Write index.html with metadata-only window global
    data_script = "window.DOCBOOK_DATA_SOURCE = '#{data_filename}'; window.DOCBOOK_FORMAT = 'dist';"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    File.write(File.join(dir, "index.html"), html)
    dir
  end

  def write_library(output_path, guides, manifest:, title: nil)
    dir = output_path.end_with?(".html") ? File.dirname(output_path) : output_path
    FileUtils.mkdir_p(dir)
    FileUtils.mkdir_p(File.join(dir, "data"))

    title ||= manifest.name || "DocBook Library"

    # Write each book's data as a separate JSON file
    books_meta = manifest.books.each_with_index.map do |book, i|
      guide = guides[i]
      data_filename = "data/#{book.id}.json"
      File.write(File.join(dir, data_filename), JSON.generate(guide))

      meta = guide["meta"] || {}
      cover = resolve_cover_dist(book, guide, dir)

      {
        "id" => book.id,
        "title" => book.title || meta["title"] || book.id,
        "author" => book.author || meta["author"],
        "description" => book.description,
        "cover" => cover,
        "source" => data_filename,
      }.compact
    end

    collection = { "name" => title, "description" => manifest.description, "books" => books_meta }
    data_script = "window.DOCBOOK_COLLECTION = #{safe_json(collection)}; window.DOCBOOK_FORMAT = 'dist';"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    File.write(File.join(dir, "index.html"), html)
    dir
  end

  private

  def resolve_cover_dist(book, guide, dir)
    # Copy cover image to data/ directory instead of embedding as data URL
    # ...
  end
end
```

### New: `lib/docbook/output/formats/paged_format.rb`

Directory. `index.html` entry point + `pages/` with per-section HTML files. Each page is a standalone HTML with its section's content.

```ruby
class PagedFormat < BaseFormat
  def write(output_path, guide, title: "DocBook", manifest: nil)
    dir = output_path.end_with?(".html") ? File.dirname(output_path) : output_path
    FileUtils.mkdir_p(dir)
    FileUtils.mkdir_p(File.join(dir, "pages"))

    toc = guide.dig("toc", "sections") || []

    # Split content by top-level sections (chapters/parts)
    sections = split_into_pages(guide["content"] || [])

    # Write each section as a separate HTML file
    page_map = {}
    sections.each_with_index do |(section_id, nodes), i|
      renderer = HtmlRenderer.new(guide)
      page_html = renderer.render_nodes(nodes)
      filename = section_id ? "pages/#{section_id}.html" : "pages/intro.html"
      page_key = section_id || "intro"

      # Each page is a standalone HTML with shared CSS/JS
      page_full = html_boilerplate(
        title: "#{title} — Page #{i + 1}",
        body_content: %(<div id="docbook-content">#{page_html}</div>\n<div id="docbook-app"></div>),
        script_data: "window.DOCBOOK_FORMAT = 'paged'; window.DOCBOOK_PAGE_ID = '#{page_key}';"
      )
      File.write(File.join(dir, filename), page_full)
      page_map[page_key] = filename
    end

    # Write index.html with TOC and page map
    data_script = "window.DOCBOOK_PAGES = #{safe_json(page_map)}; window.DOCBOOK_TOC = #{safe_json(toc)}; window.DOCBOOK_FORMAT = 'paged';"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    File.write(File.join(dir, "index.html"), html)
    dir
  end

  def write_library(output_path, guides, manifest:, title: nil)
    # For library paged mode: each book gets its own subdirectory
    # with its own pages/ directory
    dir = output_path.end_with?(".html") ? File.dirname(output_path) : output_path
    FileUtils.mkdir_p(dir)

    title ||= manifest.name || "DocBook Library"

    books_meta = manifest.books.each_with_index.map do |book, i|
      book_dir = File.join(dir, book.id)
      # Recursively write paged output for this book
      write(File.join(book_dir, "index.html"), guides[i], title: book.title || book.id)

      {
        "id" => book.id,
        "title" => book.title || guides[i].dig("meta", "title") || book.id,
        "source" => "#{book.id}/",
      }
    end

    collection = { "name" => title, "books" => books_meta }
    data_script = "window.DOCBOOK_COLLECTION = #{safe_json(collection)}; window.DOCBOOK_FORMAT = 'paged';"
    html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>', script_data: data_script)
    File.write(File.join(dir, "index.html"), html)
    dir
  end

  private

  # Split content array into pages at section/chapter/part boundaries
  def split_into_pages(content)
    pages = []
    current_id = nil
    current_nodes = []

    content.each do |node|
      if section_boundary?(node)
        pages << [current_id, current_nodes] unless current_nodes.empty?
        current_id = node.dig("attrs", "xml_id") || "section-#{pages.size + 1}"
        current_nodes = [node]
      else
        current_nodes << node
      end
    end
    pages << [current_id, current_nodes] unless current_nodes.empty?
    pages
  end

  SECTION_TYPES = %w[chapter part section appendix preface reference].freeze

  def section_boundary?(node)
    SECTION_TYPES.include?(node["type"])
  end
end
```

### Modify: `lib/docbook/output.rb`

```ruby
module Docbook
  module Output
    autoload :Pipeline, "#{__dir__}/output/pipeline"
    autoload :HtmlRenderer, "#{__dir__}/output/html_renderer"

    module Formats
      autoload :BaseFormat, "#{__dir__}/formats/base_format"
      autoload :InlineFormat, "#{__dir__}/formats/inline_format"
      autoload :DomFormat, "#{__dir__}/formats/dom_format"
      autoload :DistFormat, "#{__dir__}/formats/dist_format"
      autoload :PagedFormat, "#{__dir__}/formats/paged_format"

      FORMAT_MAP = {
        inline: InlineFormat,
        dom: DomFormat,
        dist: DistFormat,
        paged: PagedFormat,
      }.freeze
    end
  end
end
```

## Verification

1. `InlineFormat` produces correct single-HTML output with inlined data
2. `DomFormat` output contains visible HTML content when viewed without JavaScript
3. `DistFormat` creates `index.html` + `data/book.json` (or `data/<id>.json` for library)
4. `PagedFormat` creates `index.html` + `pages/*.html` with one file per chapter
5. All formats render correctly when opened in a browser
