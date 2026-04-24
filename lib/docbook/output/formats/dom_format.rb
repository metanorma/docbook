# frozen_string_literal: true

require "fileutils"

module Docbook
  module Output
    module Formats
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
          html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>',
                                  script_data: data_script)
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
