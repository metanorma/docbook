# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 4: Generate index from indexterms in the document.
      class GenerateIndex
        def call(guide, context)
          require_relative "../index_generator"
          index_collector = Docbook::Output::IndexCollector.new(context.parsed)
          index_terms = index_collector.collect
          index_generator = Docbook::Output::IndexGenerator.new(index_terms)
          index_data = index_generator.generate
          guide["index_data"] = {
            "title" => "Index",
            "type" => "index",
            "groups" => index_data,
          }
          guide
        end
      end
    end
  end
end
