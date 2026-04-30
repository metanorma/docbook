# frozen_string_literal: true

require "fileutils"

module Docbook
  module Output
    module Formats
      class ChunkedFormat < BaseFormat
        SECTION_BOUNDARY_TYPES = %w[chapter part section appendix preface reference].freeze

        def write(output_path, guide, title: "DocBook", _manifest: nil)
          dir = ensure_directory(output_path)
          FileUtils.mkdir_p(File.join(dir, "sections"))

          sections = split_into_chunks(guide["content"] || [])
          # Assign stable IDs to chunks that have no section boundary (nil ids)
          sections.each_with_index do |chunk, i|
            chunk[0] ||= "chunk-#{i + 1}"
          end
          section_ids = sections.map { |(id, _)| id }

          sections.each_with_index do |(section_id, nodes), i|
            section_data = {
              "id" => section_id,
              "content" => nodes,
              "next" => section_ids[i + 1],
              "prev" => i.positive? ? section_ids[i - 1] : nil,
            }
            File.write(File.join(dir, "sections", "#{section_id}.json"), JSON.generate(section_data))
          end

          manifest = {
            "meta" => guide["meta"] || {},
            "toc" => guide["toc"] || {},
            "total_sections" => sections.size,
            "section_ids" => section_ids,
          }
          File.write(File.join(dir, "manifest.json"), JSON.generate(manifest))

          data_script = "window.DOCBOOK_FORMAT = 'chunked'; window.DOCBOOK_MANIFEST = 'manifest.json';"
          html = html_boilerplate(title: title, body_content: '<div id="docbook-app"></div>',
                                  script_data: data_script)
          File.write(File.join(dir, "index.html"), html)
          copy_service_worker(dir)
          dir
        end

        private

        def ensure_directory(output_path)
          dir = output_path.end_with?(".html") ? File.dirname(output_path) : output_path
          FileUtils.mkdir_p(dir)
          dir
        end

        def split_into_chunks(content)
          chunks = []
          current_id = nil
          current_nodes = []

          content.each do |node|
            if section_boundary?(node)
              chunks << [current_id, current_nodes] unless current_nodes.empty?
              current_id = node.dig("attrs", "xml_id") || "section-#{chunks.size + 1}"
              current_nodes = [node]
            else
              current_nodes << node
            end
          end
          chunks << [current_id, current_nodes] unless current_nodes.empty?
          chunks
        end

        def section_boundary?(node)
          SECTION_BOUNDARY_TYPES.include?(node["type"])
        end
      end
    end
  end
end
