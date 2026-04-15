# frozen_string_literal: true

require "json"
require "base64"

module Docbook
  module Services
    # Generates a self-contained demo.html from DocBook XML.
    #
    # Orchestrates the full pipeline: parse XML → generate TOC, numbering,
    # index → transform to DocbookMirror JSON → resolve images → render HTML.
    #
    # Usage:
    #   generator = DemoGenerator.new(
    #     xml_path: "spec/fixtures/xslTNG/guide/xml/guide.xml",
    #     dist_dir: "frontend/dist",
    #     output_path: "frontend/src/demo.html",
    #     image_search_dirs: ["spec/fixtures/xslTNG/guide/resources/media"],
    #     image_strategy: :data_url
    #   )
    #   generator.generate
    #
    class DemoGenerator
      attr_reader :xml_path, :dist_dir, :output_path, :image_search_dirs, :image_strategy

      # @param xml_path [String] path to the DocBook XML file
      # @param dist_dir [String] path to the frontend dist directory (for CSS/JS)
      # @param output_path [String] path to write the demo.html
      # @param image_search_dirs [Array<String>] directories to search for images
      # @param image_strategy [Symbol] :file_url, :data_url, or :relative
      # @param title [String] page title for the HTML
      def initialize(xml_path:, dist_dir:, output_path:, image_search_dirs: [],
                     image_strategy: :data_url, title: "DocBook Library")
        @xml_path = xml_path
        @dist_dir = dist_dir
        @output_path = output_path
        @image_search_dirs = Array(image_search_dirs)
        @image_strategy = image_strategy
        @title = title
      end

      # Run the full pipeline and write demo.html
      # @return [String] the output file path
      def generate
        xml_dir = File.dirname(@xml_path)

        # 1. Parse the XML
        parsed = parse_xml

        # 2. Generate TOC
        toc_tree = TocGenerator.new(parsed).generate
        toc_sections = toc_tree.map { |node| toc_node_to_hash(node) }

        # 3. Generate numbering
        numbering_list = NumberingService.new(parsed).generate
        numbering_hash = {}
        numbering_list.each { |sn| numbering_hash[sn.id] = sn.number }

        # 4. Generate index
        require_relative "../output/index_generator"
        index_collector = Docbook::Output::IndexCollector.new(parsed)
        index_terms = index_collector.collect
        index_generator = Docbook::Output::IndexGenerator.new(index_terms)
        index_data = index_generator.generate
        index_hash = { "title" => "Index", "type" => "index", "groups" => index_data }

        # 5. Transform to DocbookMirror JSON
        require_relative "../mirror"
        require_relative "../output/docbook_mirror"
        mirror_output = Docbook::Output::DocbookMirror.new(parsed)
        guide = JSON.parse(mirror_output.to_pretty_json)

        # 6. Attach TOC, numbering, and index
        guide["toc"] = { "sections" => toc_sections, "numbering" => numbering_hash }
        guide["index"] = index_hash

        # 7. Resolve image paths
        ImageResolver.new(
          search_dirs: @image_search_dirs + [xml_dir],
          strategy: @image_strategy
        ).resolve(guide)

        # 8. Build HTML
        write_html(guide)

        @output_path
      end

      private

      def parse_xml
        xml_string = File.read(@xml_path)
        resolved_xml = Docbook::XIncludeResolver.resolve_string(xml_string, base_path: @xml_path)
        Docbook::Document.from_xml(resolved_xml.to_xml)
      end

      def toc_node_to_hash(node)
        result = {
          "id" => node.id,
          "title" => node.title,
          "type" => node.type,
          "number" => node.number
        }
        result["children"] = node.children.map { |c| toc_node_to_hash(c) } if node.children&.any?
        result.compact
      end

      def write_html(guide)
        css_content = File.read(File.join(@dist_dir, "app.css"))
        js_content = File.read(File.join(@dist_dir, "app.iife.js"))

        html = <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Bibliotheca — #{@title}</title>
            <style>#{css_content}</style>
            <script>
              window.DOCBOOK_DATA = #{JSON.generate(guide).gsub('</script', '<\\/script')};
            </script>
          </head>
          <body>
            <div id="docbook-app"></div>
            <script>#{js_content}</script>
          </body>
          </html>
        HTML

        File.write(@output_path, html)
      end
    end
  end
end
