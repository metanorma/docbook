# frozen_string_literal: true

module Docbook
  module Output
    module Formats
      # Shared library support methods for format classes.
      #
      # Provides common methods for building multi-book library data
      # and resolving cover images, extracted from InlineFormat and
      # DomFormat to eliminate duplication.
      #
      # Include this module in any format class that supports library output.
      #
      # Usage:
      #   class MyFormat < BaseFormat
      #     include LibrarySupport
      #   end
      #
      module LibrarySupport
        private

        # Build the collection data structure for multi-book libraries.
        # Embeds guide data directly (for inline/dom formats).
        def build_collection_data(guides, manifest)
          books = manifest.books.each_with_index.map do |book, i|
            guide = guides[i]
            meta = guide["meta"] || {}
            cover = resolve_cover(book, guide)

            {
              "id" => book.id,
              "title" => meta["title"] || book.title || book.id,
              "author" => book.author || meta["author"],
              "description" => book.description,
              "cover" => cover,
              "source" => "",
              "data" => guide,
            }.compact
          end

          { "name" => manifest.name, "description" => manifest.description, "books" => books }
        end

        # Resolve a cover image to a data URL.
        # Tries the book_entry cover path first, then falls back to XML cover metadata.
        def resolve_cover(book_entry, guide)
          if book_entry.cover && File.exist?(book_entry.cover)
            return embed_as_data_url(book_entry.cover)
          end

          xml_cover = guide.dig("meta", "cover")
          if xml_cover
            xml_dir = File.dirname(book_entry.source)
            abs = File.expand_path(xml_cover, xml_dir)
            return embed_as_data_url(abs) if File.exist?(abs)
          end
          nil
        end
      end
    end
  end
end
