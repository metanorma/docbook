# frozen_string_literal: true

require "json"
require_relative "index_generator"

module Docbook
  module Output
    # Shared data processing pipeline for DocBook XML.
    #
    # Orchestrates steps 1-8: parse XML, generate TOC, numbering, index,
    # transform to DocbookMirror JSON, attach metadata, generate lists,
    # and resolve image paths. Returns a complete guide hash ready for
    # consumption by any Format class.
    #
    # Usage:
    #   guide = Pipeline.new(xml_path: "book.xml").process
    #
    class Pipeline
      attr_reader :xml_path, :image_search_dirs, :image_strategy,
                  :sort_glossary, :title

      # @param xml_path [String] path to the DocBook XML file
      # @param image_search_dirs [Array<String>] directories to search for images
      # @param image_strategy [Symbol] :file_url, :data_url, or :relative
      # @param sort_glossary [Boolean] sort glossary entries alphabetically
      # @param title [String] fallback title for the document
      def initialize(xml_path:, image_search_dirs: [], image_strategy: :data_url,
                     sort_glossary: false, title: "DocBook")
        @xml_path = xml_path
        @image_search_dirs = Array(image_search_dirs)
        @image_strategy = image_strategy
        @sort_glossary = sort_glossary
        @title = title
      end

      # Run the full data processing pipeline and return the guide hash.
      # @return [Hash] the complete guide data with toc, index, meta, content
      def process
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
        mirror_output = Docbook::Output::DocbookMirror.new(parsed, sort_glossary: @sort_glossary)
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
          "cover" => stats["cover"],
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

        guide
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
    end
  end
end
