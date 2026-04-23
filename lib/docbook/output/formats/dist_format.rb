# frozen_string_literal: true

require "fileutils"

module Docbook
  module Output
    module Formats
      class DistFormat < BaseFormat
        def write(output_path, guide, title: "DocBook", manifest: nil)
          dir = ensure_directory(output_path)
          FileUtils.mkdir_p(File.join(dir, "data"))

          data_filename = "data/book.json"
          File.write(File.join(dir, data_filename), JSON.generate(guide))

          data_script = "window.DOCBOOK_DATA_SOURCE = '#{data_filename}'; window.DOCBOOK_FORMAT = 'dist';"
          html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>',
                                  script_data: data_script)
          File.write(File.join(dir, "index.html"), html)
          dir
        end

        def write_library(output_path, guides, manifest:, title: nil)
          dir = ensure_directory(output_path)
          FileUtils.mkdir_p(File.join(dir, "data"))

          title ||= manifest.name || "DocBook Library"

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
          html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>',
                                  script_data: data_script)
          File.write(File.join(dir, "index.html"), html)
          dir
        end

        private

        def ensure_directory(output_path)
          dir = output_path.end_with?(".html") ? File.dirname(output_path) : output_path
          FileUtils.mkdir_p(dir)
          dir
        end

        def resolve_cover_dist(book_entry, guide, dir)
          cover_path = nil

          if book_entry.cover && File.exist?(book_entry.cover)
            cover_path = book_entry.cover
          else
            xml_cover = guide.dig("meta", "cover")
            if xml_cover
              xml_dir = File.dirname(book_entry.source)
              abs = File.expand_path(xml_cover, xml_dir)
              cover_path = abs if File.exist?(abs)
            end
          end

          return nil unless cover_path

          ext = File.extname(cover_path)
          dest = File.join(dir, "data", "cover-#{book_entry.id}#{ext}")
          FileUtils.cp(cover_path, dest)
          "data/cover-#{book_entry.id}#{ext}"
        rescue StandardError
          nil
        end
      end
    end
  end
end
