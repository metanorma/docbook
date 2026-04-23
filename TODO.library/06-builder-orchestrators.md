# 06 — Builder & LibraryBuilder Orchestrators

## Goal

Create two orchestrator classes that compose `Pipeline` + `Format` + (for library) `CollectionManifest`. These are the high-level APIs that both the CLI and Ruby programmatic interface use.

## Design

### OCP Compliance
Builders don't contain format-specific logic. They delegate to `Formats::FORMAT_MAP[format]`. Adding a new format means adding to `FORMAT_MAP` — builders are unchanged.

### Encapsulation
Builders encapsulate the full workflow: parse manifest (if library) → process XML → format output. Consumers only see `builder.build` → output path.

### Single Responsibility
- `Builder`: single book → one Pipeline.run → one Format.write
- `LibraryBuilder`: multiple books → N Pipeline.runs → one Format.write_library

## Files

### New: `lib/docbook/output/builder.rb`

```ruby
# frozen_string_literal: true

module Docbook
  module Output
    class Builder
      attr_reader :xml_path, :output_path, :format, :options

      # @param xml_path [String] path to DocBook XML
      # @param output_path [String] path to output file or directory
      # @param format [Symbol] :inline, :dom, :dist, or :paged
      # @param options [Hash] image_search_dirs, image_strategy, sort_glossary, title, dist_dir
      def initialize(xml_path:, output_path:, format: :inline, **options)
        @xml_path = xml_path
        @output_path = output_path
        @format = format
        @options = options
      end

      # Run the pipeline and write output
      # @return [String] output path
      def build
        pipeline = Pipeline.new(
          xml_path: @xml_path,
          image_search_dirs: @options[:image_search_dirs] || [],
          image_strategy: @options[:image_strategy] || :data_url,
          sort_glossary: @options[:sort_glossary] || false,
          title: @options[:title] || File.basename(@xml_path, ".*"),
        )

        guide = pipeline.process

        format_class = Formats::FORMAT_MAP[@format]
        raise ArgumentError, "Unknown format: #{@format}" unless format_class

        formatter = format_class.new(dist_dir: @options[:dist_dir])
        formatter.write(@output_path, guide, title: @options[:title])

        @output_path
      end
    end
  end
end
```

### New: `lib/docbook/output/library_builder.rb`

```ruby
# frozen_string_literal: true

module Docbook
  module Output
    class LibraryBuilder
      attr_reader :input_path, :output_path, :format, :options

      # @param input_path [String] path to manifest file or directory
      # @param output_path [String] path to output file or directory
      # @param format [Symbol] :inline, :dom, :dist, or :paged
      # @param options [Hash] image_strategy, sort_glossary, title, dist_dir
      def initialize(input_path:, output_path:, format: :inline, **options)
        @input_path = input_path
        @output_path = output_path
        @format = format
        @options = options
      end

      # Process all books and write library output
      # @return [String] output path
      def build
        manifest = Services::CollectionManifestResolver.new(@input_path).resolve

        if manifest.books.empty?
          raise ArgumentError, "No DocBook XML files found in #{@input_path}"
        end

        # Process each book through the pipeline
        guides = manifest.books.map do |book|
          Pipeline.new(
            xml_path: book.xml_path,
            image_strategy: @options[:image_strategy] || :data_url,
            sort_glossary: @options[:sort_glossary] || false,
            title: book.title || File.basename(book.xml_path, ".*"),
          ).process
        end

        # Delegate to format
        format_class = Formats::FORMAT_MAP[@format]
        raise ArgumentError, "Unknown format: #{@format}" unless format_class

        formatter = format_class.new(dist_dir: @options[:dist_dir])
        formatter.write_library(@output_path, guides, manifest: manifest, title: @options[:title)

        @output_path
      end
    end
  end
end
```

### Modify: `lib/docbook/output.rb`

Add autoloads:
```ruby
autoload :Builder, "#{__dir__}/output/builder"
autoload :LibraryBuilder, "#{__dir__}/output/library_builder"
```

## Ruby API Usage

After this step, users can build outputs programmatically:

```ruby
# Single book — any format
Docbook::Output::Builder.new(
  xml_path: "book.xml",
  output_path: "output.html",
  format: :inline,  # or :dom, :dist, :paged
).build

# Library — any format
Docbook::Output::LibraryBuilder.new(
  input_path: "library.yml",  # or directory path
  output_path: "library.html",
  format: :inline,
).build
```

## Verification

1. `Builder.new(xml_path: "kitchen-sink.xml", output_path: "/tmp/out.html", format: :inline).build` produces correct output
2. `Builder` works with all 4 format symbols
3. `LibraryBuilder` processes all books from a manifest directory
4. `LibraryBuilder` raises on empty directory
5. `bundle exec rspec` — no regressions
