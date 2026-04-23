# 05 — Collection Manifest Models & Resolver

## Goal

Define the collection manifest data model using Lutaml::Model (`json do` mapping) and create a resolver service that parses manifests from directories, YAML files, or JSON files.

## Design

### OCP Compliance
The manifest model is a data contract. Adding new fields (e.g., `tags`, `category`) means adding attributes to the model — consumers that don't use those fields are unaffected.

### Encapsulation
`Services::CollectionManifest` hides all parsing logic (directory scanning, YAML loading, path resolution). Consumers receive a fully resolved manifest model.

### Model-Driven
`BookEntry` and `CollectionManifest` are Lutaml::Model classes. They define the schema. The resolver populates them. Format classes consume them.

## Files

### New: `lib/docbook/models/book_entry.rb`

```ruby
# frozen_string_literal: true

module Docbook
  module Models
    class BookEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :source, :string          # relative path to DocBook XML
      attribute :title, :string
      attribute :author, :string
      attribute :description, :string
      attribute :cover, :string           # relative path to cover image

      json do
        map "id", to: :id
        map "source", to: :source
        map "title", to: :title
        map "author", to: :author
        map "description", to: :description
        map "cover", to: :cover
      end
    end
  end
end
```

### New: `lib/docbook/models/collection_manifest.rb`

```ruby
# frozen_string_literal: true

module Docbook
  module Models
    class CollectionManifest < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :description, :string
      attribute :books, BookEntry, collection: true

      json do
        map "name", to: :name
        map "description", to: :description
        map "books", to: :books
      end
    end
  end
end
```

### Modify: `lib/docbook/models.rb`

Add autoloads:
```ruby
autoload :BookEntry, "#{MODELS_DIR}/book_entry"
autoload :CollectionManifest, "#{MODELS_DIR}/collection_manifest"
```

### New: `lib/docbook/services/collection_manifest.rb`

```ruby
# frozen_string_literal: true

require "json"

module Docbook
  module Services
    class CollectionManifestResolver
      # Represents a resolved book entry with absolute paths
      ResolvedBook = Struct.new(
        :id, :xml_path, :title, :author, :description, :cover_path,
        keyword_init: true
      )

      COVER_FILENAMES = %w[cover.png cover.jpg cover.jpeg cover.gif cover.svg cover.webp].freeze

      # @param input_path [String] path to manifest file or directory
      def initialize(input_path)
        @input_path = File.expand_path(input_path)
        @base_dir = File.directory?(@input_path) ? @input_path : File.dirname(@input_path)
      end

      # Parse and resolve the manifest
      # @return [Struct] with :name, :description, :books (Array<ResolvedBook>)
      def resolve
        raw = if File.directory?(@input_path)
                parse_directory
              elsif yaml_file?(@input_path)
                parse_yaml
              else
                parse_json
              end

        resolve_paths(raw)
      end

      private

      # --- Parsing ---

      def parse_directory
        books = []
        Dir.glob(File.join(@input_path, "*")).sort.each do |entry|
          next unless File.directory?(entry)
          xml_files = Dir.glob(File.join(entry, "*.xml"))
          next if xml_files.empty?

          book_id = File.basename(entry)
          books << Models::BookEntry.new(
            id: book_id,
            source: File.join(book_id, File.basename(xml_files.first)),
          )
        end

        Models::CollectionManifest.new(
          name: File.basename(@input_path),
          books: books,
        )
      end

      def parse_yaml
        require "yaml"
        data = YAML.safe_load(File.read(@input_path), permitted_classes: [Date, Time])
        Models::CollectionManifest.from_json(data.to_json)  # reuse json mapping
      end

      def parse_json
        Models::CollectionManifest.from_json(File.read(@input_path))
      end

      def yaml_file?(path)
        File.extname(path).match?(/\.ya?ml$/i)
      end

      # --- Path resolution ---

      def resolve_paths(manifest)
        resolved_books = manifest.books.map do |book|
          xml_path = File.expand_path(book.source, @base_dir)
          cover_path = resolve_cover_path(book, xml_path)

          ResolvedBook.new(
            id: book.id || File.basename(xml_path, ".*"),
            xml_path: xml_path,
            title: book.title,
            author: book.author,
            description: book.description,
            cover_path: cover_path,
          )
        end

        OpenStruct.new(
          name: manifest.name,
          description: manifest.description,
          books: resolved_books,
        )
      end

      def resolve_cover_path(book, xml_path)
        # Priority 1: Manifest-specified cover
        if book.cover
          path = File.expand_path(book.cover, @base_dir)
          return path if File.exist?(path)
        end

        # Priority 2: Convention file in book directory
        book_dir = File.dirname(xml_path)
        COVER_FILENAMES.each do |name|
          path = File.join(book_dir, name)
          return path if File.exist?(path)
        end

        nil  # Priority 3: XML <cover> element — resolved later during Pipeline.process
      end
    end
  end
end
```

### Modify: `lib/docbook/services.rb`

Add autoload:
```ruby
autoload :CollectionManifestResolver, "#{SERVICES_DIR}/collection_manifest"
```

## Manifest Format Specification

### YAML

```yaml
name: "My Technical Library"         # Library display name
description: "A curated collection"  # Shown on library index page

books:
  - id: "user-guide"                 # Unique identifier (required)
    source: "user-guide/guide.xml"   # Path to DocBook XML, relative to manifest (required)
    title: "User Guide v3.0"         # Override title (optional)
    author: "Acme Corp"              # Override author (optional)
    description: "Complete user..."  # Book description for card (optional)
    cover: "user-guide/cover.png"    # Override cover path (optional)

  - id: "api-reference"
    source: "api/api-ref.xml"
    # title, author, description, cover all auto-extracted from XML
```

### JSON

```json
{
  "name": "My Technical Library",
  "description": "A curated collection",
  "books": [
    {
      "id": "user-guide",
      "source": "user-guide/guide.xml",
      "title": "User Guide v3.0",
      "cover": "user-guide/cover.png"
    }
  ]
}
```

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | no | Library display name (defaults to directory name) |
| `description` | string | no | Library description shown on index page |
| `books` | array | yes | Array of book entries |
| `books[].id` | string | yes* | Unique book identifier (*auto-derived from directory name) |
| `books[].source` | string | yes* | Path to DocBook XML, relative to manifest (*auto-discovered) |
| `books[].title` | string | no | Override title (defaults to XML `<info><title>`) |
| `books[].author` | string | no | Override author (defaults to XML `<info><author>`) |
| `books[].description` | string | no | Book description shown on BookCard |
| `books[].cover` | string | no | Path to cover image, relative to manifest |

### Cover Resolution Priority

1. Manifest `cover:` field (explicit path)
2. Convention file in book directory: `cover.{png,jpg,jpeg,gif,svg,webp}`
3. XML `<info><cover><mediaobject>` element (resolved during Pipeline.process)

## Verification

1. Parse `library.yml` → verify all paths resolved to absolute
2. Parse directory with 2 book subdirs → verify auto-discovery
3. Cover convention: place `cover.png` in book dir → verify auto-detected
4. Parse JSON manifest → verify same results as YAML
5. `bundle exec rspec` — all existing tests pass
