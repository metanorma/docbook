# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 3: Generate section numbering.
      class GenerateNumbering
        def call(guide, context)
          numbering_list = Services::NumberingService.new(context.parsed).generate
          numbering_hash = {}
          numbering_list.each { |sn| numbering_hash[sn.id] = sn.number }
          guide["numbering"] = numbering_hash
          guide
        end
      end
    end
  end
end
