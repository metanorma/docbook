# frozen_string_literal: true

require "json"
require "base64"
require_relative "index_generator"

module Docbook
  module Output
    # Generates a self-contained single-page HTML from DocBook XML.
    #
    # Orchestrates the full pipeline: parse XML → generate TOC, numbering,
    # index → transform to DocbookMirror JSON → resolve images → render HTML.
    #
    # Usage:
    #   page = Docbook::Output::SinglePage.new(
    #     xml_path: "guide.xml",
    #     dist_dir: "frontend/dist",
    #     output_path: "output/guide.html",
    #     image_search_dirs: ["resources/media"],
    #     image_strategy: :data_url
    #   )
    #   page.generate
    #
    class SinglePage
      attr_reader :xml_path, :dist_dir, :output_path, :image_search_dirs,
                  :image_strategy

      # @param xml_path [String] path to the DocBook XML file
      # @param dist_dir [String] path to the frontend dist directory (defaults to gem's bundled frontend)
      # @param output_path [String] path to write the output HTML file
      # @param image_search_dirs [Array<String>] directories to search for images
      # @param image_strategy [Symbol] :file_url, :data_url, or :relative
      # @param title [String] page title for the HTML
      def initialize(xml_path:, output_path:, dist_dir: nil, image_search_dirs: [],
                     image_strategy: :data_url, title: "DocBook Library")
        @xml_path = xml_path
        @dist_dir = dist_dir || FRONTEND_DIST
        @output_path = output_path
        @image_search_dirs = Array(image_search_dirs)
        @image_strategy = image_strategy
        @title = title
      end

      # Run the full pipeline and write the HTML file.
      # @return [String] the output file path
      def generate
        xml_dir = File.dirname(@xml_path)

        # 1. Parse the XML
        parsed = parse_xml

        # 2. Generate TOC
        toc_tree = Services::TocGenerator.new(parsed).generate
        toc_sections = toc_tree.map { |node| toc_node_to_hash(node) }

        # 3. Generate numbering
        numbering_list = Services::NumberingService.new(parsed).generate
        numbering_hash = {}
        numbering_list.each { |sn| numbering_hash[sn.id] = sn.number }

        # 4. Generate index
        index_collector = Docbook::Output::IndexCollector.new(parsed)
        index_terms = index_collector.collect
        index_generator = Docbook::Output::IndexGenerator.new(index_terms)
        index_data = index_generator.generate
        index_hash = { "title" => "Index", "type" => "index",
                       "groups" => index_data }

        # 5. Transform to DocbookMirror JSON
        require_relative "../mirror"
        require_relative "docbook_mirror"
        mirror_output = Docbook::Output::DocbookMirror.new(parsed)
        guide = JSON.parse(mirror_output.to_pretty_json)

        # 6. Attach TOC, numbering, index, and metadata
        guide["toc"] =
          { "sections" => toc_sections, "numbering" => numbering_hash }
        guide["index"] = index_hash

        stats = Services::DocumentStats.new(parsed).generate
        guide["meta"] = {
          "title" => stats["title"] || @title,
          "subtitle" => stats["subtitle"],
          "author" => stats["author"],
          "pubdate" => stats["pubdate"],
          "releaseinfo" => stats["releaseinfo"],
          "copyright" => stats["copyright"],
          "root_element" => stats["root_element"],
        }.compact

        # 7. Generate lists of figures/tables/examples
        list_of = Services::ListOfGenerator.new(parsed).generate(numbering: numbering_hash)
        list_of.each do |type, entries|
          guide["list_of_#{type}"] = entries.map do |e|
            {
              "id" => e.id,
              "title" => e.title,
              "number" => e.number,
              "section_id" => e.section_id,
              "section_title" => e.section_title,
            }.compact
          end
        end

        # 8. Resolve image paths
        Services::ImageResolver.new(
          search_dirs: @image_search_dirs + [xml_dir],
          strategy: @image_strategy,
        ).resolve(guide)

        # 9. Build HTML
        write_html(guide)

        @output_path
      end

      private

      def parse_xml
        xml_string = File.read(@xml_path)
        resolved_xml = Docbook::XIncludeResolver.resolve_string(xml_string,
                                                                base_path: @xml_path)
        Docbook::Document.from_xml(resolved_xml.to_xml)
      end

      def toc_node_to_hash(node)
        result = {
          "id" => node.id,
          "title" => node.title,
          "type" => node.type,
          "number" => node.number,
        }
        if node.children&.any?
          result["children"] = node.children.map do |c|
            toc_node_to_hash(c)
          end
        end
        result.compact
      end

      FRONTEND_DIST = File.expand_path("../../../frontend/dist", __dir__)

      def write_html(guide)
        dist = @dist_dir || FRONTEND_DIST
        css_content = File.read(File.join(dist, "app.css"))
        js_content = File.read(File.join(dist, "app.iife.js"))

        html = <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{@title}</title>
            <style>#{css_content}</style>
            <script>
              window.DOCBOOK_DATA = #{JSON.generate(guide).gsub("</script", '<\\/script')};
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
