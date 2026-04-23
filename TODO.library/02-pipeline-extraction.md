# 02 — Pipeline Extraction

## Goal

Extract the shared data processing logic from `SinglePage` into a new `Pipeline` class. **Delete `SinglePage` entirely** — the `Builder` class replaces it as the single-book entry point.

## Current State

`SinglePage#generate` (`lib/docbook/output/single_page.rb`, lines 49-117) runs 9 sequential steps:
1. Parse XML
2. Generate TOC
3. Generate numbering
4. Generate index
5. Transform to DocbookMirror JSON
6. Attach TOC, numbering, index, metadata
7. Generate lists of figures/tables/examples
8. Resolve image paths
9. Write HTML (the only step that's format-specific)

Steps 1-8 are pure data transformation. Step 9 is output. Currently they're entangled in one method.

## Design

### OCP Compliance
`Pipeline` is closed for modification — its processing steps are stable. Format classes consume the pipeline's output without knowing how it was produced. Adding a new format never touches `Pipeline`.

### Encapsulation
`Pipeline` hides all 8 processing steps behind a single `#process` method. Consumers don't know about TocGenerator, NumberingService, IndexGenerator, ImageResolver, etc.

### File: New `lib/docbook/output/pipeline.rb`

```ruby
module Docbook
  module Output
    class Pipeline
      attr_reader :xml_path, :image_search_dirs, :image_strategy,
                  :sort_glossary, :title

      def initialize(xml_path:, image_search_dirs: [], image_strategy: :data_url,
                     sort_glossary: false, title: "DocBook")
        @xml_path = xml_path
        @image_search_dirs = Array(image_search_dirs)
        @image_strategy = image_strategy
        @sort_glossary = sort_glossary
        @title = title
      end

      # Runs steps 1-8, returns the complete guide hash
      def process
        xml_dir = File.dirname(@xml_path)

        # Step 1: Parse
        parsed = parse_xml

        # Step 2: TOC
        toc_tree = Services::TocGenerator.new(parsed).generate
        toc_sections = toc_tree.map { |node| toc_node_to_hash(node) }

        # Step 3: Numbering
        numbering_list = Services::NumberingService.new(parsed).generate
        numbering_hash = {}
        numbering_list.each { |sn| numbering_hash[sn.id] = sn.number }

        # Step 4: Index
        index_collector = Docbook::Output::IndexCollector.new(parsed)
        index_terms = index_collector.collect
        index_data = Docbook::Output::IndexGenerator.new(index_terms).generate
        index_hash = { "title" => "Index", "type" => "index", "groups" => index_data }

        # Step 5: DocbookMirror JSON
        mirror_output = Docbook::Output::DocbookMirror.new(parsed, sort_glossary: @sort_glossary)
        guide = JSON.parse(mirror_output.to_pretty_json)

        # Step 6: Attach TOC, numbering, index, metadata
        guide["toc"] = { "sections" => toc_sections, "numbering" => numbering_hash }
        guide["index"] = index_hash

        stats = Services::DocumentStats.new(parsed).generate
        guide["meta"] = {
          "title" => stats["title"] || @title,
          "subtitle" => stats["subtitle"],
          "author" => stats["author"],
          "pubdate" => stats["pubdate"],
          "releaseinfo" => stats["releaseinfo"],
          "copyright" => stats["copyright"],
          "cover" => stats["cover"],
          "root_element" => stats["root_element"],
        }.compact

        # Step 7: Lists of figures/tables/examples
        list_of = Services::ListOfGenerator.new(parsed).generate(numbering: numbering_hash)
        list_of.each do |type, entries|
          guide["list_of_#{type}"] = entries.map do |e|
            { "id" => e.id, "title" => e.title, "number" => e.number,
              "section_id" => e.section_id, "section_title" => e.section_title }.compact
          end
        end

        # Step 8: Resolve images
        Services::ImageResolver.new(
          search_dirs: @image_search_dirs + [xml_dir],
          strategy: @image_strategy,
        ).resolve(guide)

        guide
      end

      private

      def parse_xml
        xml_string = File.read(@xml_path)
        resolved_xml = Docbook::XIncludeResolver.resolve_string(xml_string, base_path: @xml_path)
        Docbook::Document.from_xml(resolved_xml.to_xml)
      end

      def toc_node_to_hash(node)
        result = { "id" => node.id, "title" => node.title, "type" => node.type, "number" => node.number }
        if node.children&.any?
          result["children"] = node.children.map { |c| toc_node_to_hash(c) }
        end
        result.compact
      end
    end
  end
end
```

### Delete: `lib/docbook/output/single_page.rb`

`SinglePage` is replaced by `Builder` + `Pipeline` + `InlineFormat`. Remove it entirely. Update any references:

- **CLI** (`cli.rb`): change `Docbook::Output::SinglePage.new(...)` to `Docbook::Output::Builder.new(...)`
- **Tests**: update any specs that instantiate `SinglePage` to use `Builder` or `Pipeline`
- **Autoload** (`output.rb`): remove `autoload :SinglePage`

### Modify: `lib/docbook/output.rb`

```ruby
module Docbook
  module Output
    autoload :Pipeline, "#{__dir__}/output/pipeline"
    # SinglePage removed — Builder replaces it
  end
end
```

## Verification

1. `docbook build spec/fixtures/kitchen-sink/kitchen-sink.xml -o /tmp/test.html` works via `Builder` → `Pipeline` → `InlineFormat`
2. `Pipeline.new(xml_path: "...").process` returns the complete guide hash
3. `bundle exec rspec` — all existing tests updated and passing
4. No references to `SinglePage` remain in the codebase
