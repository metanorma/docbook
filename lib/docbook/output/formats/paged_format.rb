# frozen_string_literal: true

require "fileutils"

module Docbook
  module Output
    module Formats
      class PagedFormat < BaseFormat
        SECTION_BOUNDARY_TYPES = %w[chapter part section appendix preface reference].freeze

        def write(output_path, guide, title: "DocBook", _manifest: nil)
          dir = ensure_directory(output_path)
          FileUtils.mkdir_p(File.join(dir, "pages"))

          toc = guide.dig("toc", "sections") || []
          sections = split_into_pages(guide["content"] || [])

          page_map = {}
          sections.each_with_index do |(section_id, nodes), i|
            renderer = HtmlRenderer.new(guide)
            page_html = renderer.render_nodes(nodes)
            filename = section_id ? "pages/#{section_id}.html" : "pages/intro.html"
            page_key = section_id || "intro"

            page_full = html_boilerplate(
              title: "#{title} — Page #{i + 1}",
              body_content: %(<div id="docbook-content">#{page_html}</div>\n<div id="docbook-app"></div>),
              script_data: "window.DOCBOOK_FORMAT = 'paged'; window.DOCBOOK_PAGE_ID = '#{page_key}';",
            )
            File.write(File.join(dir, filename), page_full)
            page_map[page_key] = filename
          end

          data_script = "window.DOCBOOK_PAGES = #{safe_json(page_map)}; window.DOCBOOK_TOC = #{safe_json(toc)}; window.DOCBOOK_FORMAT = 'paged';"
          html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>',
                                  script_data: data_script)
          File.write(File.join(dir, "index.html"), html)
          dir
        end

        def write_library(output_path, guides, manifest:, title: nil)
          dir = ensure_directory(output_path)
          title ||= manifest.name || "DocBook Library"

          books_meta = manifest.books.each_with_index.map do |book, i|
            book_dir = File.join(dir, book.id)
            write(File.join(book_dir, "index.html"), guides[i],
                  title: book.title || book.id)

            {
              "id" => book.id,
              "title" => book.title || guides[i].dig("meta", "title") || book.id,
              "source" => "#{book.id}/",
            }
          end

          collection = { "name" => title, "books" => books_meta }
          data_script = "window.DOCBOOK_COLLECTION = #{safe_json(collection)}; window.DOCBOOK_FORMAT = 'paged';"
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

        def section_boundary?(node)
          SECTION_BOUNDARY_TYPES.include?(node["type"])
        end
      end
    end
  end
end
