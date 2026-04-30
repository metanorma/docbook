# frozen_string_literal: true

require_relative "pipeline/context"
require_relative "pipeline_steps"

module Docbook
  module Output
    # Composable data processing pipeline for DocBook XML.
    #
    # Orchestrates steps that parse XML, generate TOC, numbering, index,
    # transform to DocbookMirror JSON, attach metadata, generate lists,
    # and resolve image paths. Returns a complete guide hash ready for
    # consumption by any Format class.
    #
    # Steps are pluggable — pass a custom step list to add, remove, or
    # reorder processing stages without modifying this class.
    #
    # Usage:
    #   guide = Pipeline.new(xml_path: "book.xml").process
    #
    #   # Custom pipeline with extra step
    #   steps = Pipeline::DEFAULT_STEPS.dup.insert(5, MyCustomStep)
    #   guide = Pipeline.new(xml_path: "book.xml", steps: steps).process
    #
    class Pipeline
      DEFAULT_STEPS = [
        PipelineSteps::ParseXml,
        PipelineSteps::AssignIds,
        PipelineSteps::GenerateToc,
        PipelineSteps::GenerateNumbering,
        PipelineSteps::GenerateIndex,
        PipelineSteps::TransformMirror,
        PipelineSteps::AttachMetadata,
        PipelineSteps::GenerateLists,
        PipelineSteps::ResolveImages,
      ].freeze

      attr_reader :steps, :context

      # @param xml_path [String] path to the DocBook XML file
      # @param steps [Array<Class>] pipeline step classes (must implement #call(guide, context))
      # @param image_search_dirs [Array<String>] directories to search for images
      # @param image_strategy [Symbol] :file_url, :data_url, or :relative
      # @param sort_glossary [Boolean] sort glossary entries alphabetically
      # @param title [String] fallback title for the document
      def initialize(xml_path:, steps: DEFAULT_STEPS, image_search_dirs: [],
                     image_strategy: :data_url, sort_glossary: false, title: "DocBook")
        @steps = steps
        @context = PipelineContext.new(
          xml_path: xml_path,
          image_search_dirs: Array(image_search_dirs),
          image_strategy: image_strategy,
          sort_glossary: sort_glossary,
          title: title,
          parsed: nil
        )
      end

      # Run the pipeline and return the complete guide hash.
      # @return [Hash] the guide data with toc, index, meta, content
      def process
        guide = {}
        @steps.reduce(guide) do |current_guide, step_class|
          step_class.new.call(current_guide, @context)
        end
      end
    end
  end
end
