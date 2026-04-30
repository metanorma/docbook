# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 7: Generate lists of figures, tables, and examples.
      class GenerateLists
        def call(guide, context)
          numbering_hash = guide.dig("toc", "numbering") || {}
          list_of = Services::ListOfGenerator.new(context.parsed).generate(numbering: numbering_hash)
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
          guide
        end
      end
    end
  end
end
