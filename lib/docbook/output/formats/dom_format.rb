# frozen_string_literal: true

require "fileutils"

module Docbook
  module Output
    module Formats
      class DomFormat < BaseFormat
        include LibrarySupport

        def write(output_path, guide, title: "DocBook", _manifest: nil)
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
      end
    end
  end
end
