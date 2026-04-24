# frozen_string_literal: true

require "fileutils"
require "json"
require "base64"

module Docbook
  module Output
    module Formats
      class BaseFormat
        FRONTEND_DIST = File.expand_path("../../../../frontend/dist", __dir__)

        attr_reader :dist_dir

        def initialize(dist_dir: nil)
          @dist_dir = dist_dir || FRONTEND_DIST
        end

        def write(output_path, guide, title: "DocBook", manifest: nil)
          raise NotImplementedError, "#{self.class}#write not implemented"
        end

        def write_library(output_path, guides, manifest:, title: nil)
          raise NotImplementedError, "#{self.class}#write_library not implemented"
        end

        protected

        def dist_assets
          {
            css: File.read(File.join(@dist_dir, "app.css")),
            js: File.read(File.join(@dist_dir, "app.iife.js")),
          }
        end

        def safe_json(data)
          JSON.generate(data).gsub("</script", '<\\/script')
        end

        def html_boilerplate(title:, body_content:, head_extra: "", script_data: nil)
          assets = dist_assets
          data_script = script_data ? %(<script>\n#{script_data}\n</script>) : ""

          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>#{title}</title>
              <style>#{assets[:css]}</style>
              #{data_script}
              #{head_extra}
            </head>
            <body>
              #{body_content}
              <script>#{assets[:js]}</script>
            </body>
            </html>
          HTML
        end

        def embed_as_data_url(path)
          return nil unless path && File.exist?(path)

          mime = mime_type(path)
          return path unless mime

          data = File.binread(path)
          "data:#{mime};base64,#{Base64.strict_encode64(data)}"
        rescue StandardError
          path
        end

        def mime_type(path)
          case File.extname(path).downcase
          when ".png"  then "image/png"
          when ".jpg", ".jpeg" then "image/jpeg"
          when ".gif"  then "image/gif"
          when ".svg"  then "image/svg+xml"
          when ".webp" then "image/webp"
          end
        end
      end
    end
  end
end
