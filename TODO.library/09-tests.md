# 09 — Tests

## Goal

Comprehensive test coverage for all new components: cover extraction, pipeline, HTML renderer, format classes, collection manifest, builders, and CLI commands.

## Test Fixtures

### New: `spec/fixtures/library_sample/`

```
library_sample/
  book-one/
    book-one.xml          # Simple DocBook book with <info>, chapters, images
    cover.png             # Test cover image (1x1 pixel PNG)
  book-two/
    book-two.xml          # Another DocBook book
  library.yml             # YAML manifest pointing to both books
  library.json            # JSON equivalent
```

### Use existing fixtures

- `spec/fixtures/kitchen-sink/kitchen-sink.xml` — comprehensive DocBook with all element types
- `spec/fixtures/xslTNG/test/resources/xml/book.014.xml` — has `<cover>` element for cover extraction tests

## New Spec Files

### `spec/docbook/elements/cover_spec.rb`

```ruby
describe Docbook::Elements::Cover do
  it "parses <cover> with <mediaobject>" do
    xml = <<~XML
      <cover xmlns="http://docbook.org/ns/docbook">
        <mediaobject>
          <imageobject>
            <imagedata fileref="cover.png"/>
          </imageobject>
        </mediaobject>
      </cover>
    XML
    cover = Docbook::Elements::Cover.from_xml(xml)
    expect(cover.mediaobject).not_to be_empty
    expect(cover.mediaobject.first.imageobject.first.imagedata.fileref).to eq("cover.png")
  end
end
```

### `spec/docbook/services/document_stats_cover_spec.rb`

```ruby
describe Docbook::Services::DocumentStats, "#generate" do
  it "extracts cover from <info>" do
    # Parse book.014.xml which has <cover> element
    parsed = Docbook::Document.from_xml(File.read("spec/fixtures/xslTNG/test/resources/xml/book.014.xml"))
    stats = Docbook::Services::DocumentStats.new(parsed).generate
    expect(stats["cover"]).to eq("../media/yoyodyne.png")
  end

  it "returns nil cover when no <cover> element" do
    parsed = Docbook::Document.from_xml(File.read("spec/fixtures/article/article.xml"))
    stats = Docbook::Services::DocumentStats.new(parsed).generate
    expect(stats["cover"]).to be_nil
  end
end
```

### `spec/docbook/output/pipeline_spec.rb`

```ruby
describe Docbook::Output::Pipeline do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }

  it "produces a guide hash with all required keys" do
    guide = described_class.new(xml_path: xml_path).process
    expect(guide).to include("type" => "doc")
    expect(guide).to include("toc", "index", "meta", "content")
    expect(guide["meta"]).to include("title", "root_element")
  end

  it "produces same output as SinglePage#generate_data" do
    # Verify the extraction produces identical data
    pipeline_guide = described_class.new(xml_path: xml_path).process

    # Compare with original SinglePage internals (before refactor)
    # This test verifies the refactor was lossless
  end
end
```

### `spec/docbook/output/html_renderer_spec.rb`

```ruby
describe Docbook::Output::HtmlRenderer do
  it "renders paragraphs" do
    guide = { "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello" }] }] }
    html = described_class.new(guide).render
    expect(html).to include("<p class=\"db-paragraph\">Hello</p>")
  end

  it "renders code blocks with language" do
    guide = { "content" => [{ "type" => "code_block", "attrs" => { "text" => "puts 'hi'", "language" => "ruby" } }] }
    html = described_class.new(guide).render
    expect(html).to include("language-ruby")
    expect(html).to include("puts &#39;hi&#39;")
  end

  it "renders admonitions" do
    guide = { "content" => [{ "type" => "admonition", "attrs" => { "admonition_type" => "warning" }, "content" => [] }] }
    html = described_class.new(guide).render
    expect(html).to include("db-admonition--warning")
  end

  it "renders inline marks" do
    guide = { "content" => [{ "type" => "paragraph", "content" => [
      { "type" => "text", "text" => "bold", "marks" => [{ "type" => "strong" }] }
    ] }] }
    html = described_class.new(guide).render
    expect(html).to include("<strong>bold</strong>")
  end

  it "renders sections with anchors" do
    guide = { "content" => [{ "type" => "chapter", "attrs" => { "title" => "Intro", "xml_id" => "ch1" }, "content" => [] }] }
    html = described_class.new(guide).render
    expect(html).to include('id="ch1"')
    expect(html).to include("Intro")
  end

  it "renders a full kitchen-sink document" do
    guide = Docbook::Output::Pipeline.new(xml_path: "spec/fixtures/kitchen-sink/kitchen-sink.xml").process
    html = described_class.new(guide).render
    expect(html).to include("<section")
    expect(html).to include("<p class=\"db-paragraph\">")
  end
end
```

### `spec/docbook/output/formats/inline_format_spec.rb`

```ruby
describe Docbook::Output::Formats::InlineFormat do
  it "writes a single HTML file with inlined data" do
    guide = { "type" => "doc", "content" => [] }
    format = described_class.new
    output = Tempfile.new(["test", ".html"])
    format.write(output.path, guide, title: "Test")
    html = File.read(output.path)
    expect(html).to include("window.DOCBOOK_DATA")
    expect(html).to include("<style>")
    expect(html).to include("<script>")
  end
end
```

### `spec/docbook/output/formats/dom_format_spec.rb`

```ruby
describe Docbook::Output::Formats::DomFormat do
  it "writes a single HTML with pre-rendered content" do
    guide = Docbook::Output::Pipeline.new(xml_path: "spec/fixtures/article/article.xml").process
    format = described_class.new
    output = Tempfile.new(["test", ".html"])
    format.write(output.path, guide, title: "Test")
    html = File.read(output.path)
    expect(html).to include('id="docbook-content"')
    expect(html).to include("<p class=\"db-paragraph\">")
    expect(html).to include("window.DOCBOOK_FORMAT = 'dom'")
  end
end
```

### `spec/docbook/output/formats/dist_format_spec.rb`

```ruby
describe Docbook::Output::Formats::DistFormat do
  it "creates directory with index.html and data/book.json" do
    guide = { "type" => "doc", "content" => [] }
    format = described_class.new
    dir = Dir.mktmpdir
    format.write(File.join(dir, "index.html"), guide, title: "Test")
    expect(File.exist?(File.join(dir, "index.html"))).to be true
    expect(File.exist?(File.join(dir, "data", "book.json"))).to be true
  end
end
```

### `spec/docbook/output/formats/paged_format_spec.rb`

```ruby
describe Docbook::Output::Formats::PagedFormat do
  it "creates directory with pages" do
    guide = Docbook::Output::Pipeline.new(xml_path: "spec/fixtures/kitchen-sink/kitchen-sink.xml").process
    format = described_class.new
    dir = Dir.mktmpdir
    format.write(File.join(dir, "index.html"), guide, title: "Test")
    expect(File.exist?(File.join(dir, "index.html"))).to be true
    expect(Dir.glob(File.join(dir, "pages", "*.html"))).not_to be_empty
  end
end
```

### `spec/docbook/services/collection_manifest_spec.rb`

```ruby
describe Docbook::Services::CollectionManifestResolver do
  it "parses YAML manifest" do
    manifest = described_class.new("spec/fixtures/library_sample/library.yml").resolve
    expect(manifest.name).to eq("Test Library")
    expect(manifest.books.size).to eq(2)
    expect(manifest.books.first.xml_path).to end_with("book-one.xml")
  end

  it "parses JSON manifest" do
    manifest = described_class.new("spec/fixtures/library_sample/library.json").resolve
    expect(manifest.books.size).to eq(2)
  end

  it "auto-discovers from directory" do
    manifest = described_class.new("spec/fixtures/library_sample").resolve
    expect(manifest.books.size).to be >= 2
  end

  it "finds cover by convention" do
    manifest = described_class.new("spec/fixtures/library_sample/library.yml").resolve
    book_with_cover = manifest.books.find { |b| b.id == "book-one" }
    expect(book_with_cover.cover_path).to end_with("cover.png")
  end

  it "raises on non-existent path" do
    expect { described_class.new("/nonexistent").resolve }.to raise_error(StandardError)
  end
end
```

### `spec/docbook/output/builder_spec.rb` and `spec/docbook/output/library_builder_spec.rb`

Integration tests that exercise the full Pipeline → Format flow for single books and libraries respectively.

### Modify: `spec/cli_spec.rb`

Add tests for:
- `docbook build INPUT --format dom`
- `docbook build INPUT --format dist`
- `docbook build INPUT --format paged`
- `docbook library DIRECTORY`
- `docbook library MANIFEST.yml`
- `docbook library DIRECTORY --format dist`

## Verification

1. `bundle exec rspec` — all new and existing tests pass
2. Each format class has at least one integration test with real XML input
3. Collection manifest parsing tested for YAML, JSON, and directory modes
4. HTML renderer tested for all major node types
