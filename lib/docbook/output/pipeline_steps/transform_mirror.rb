# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 5: Transform parsed DocBook document to DocbookMirror.
      class TransformMirror
        def call(guide, context)
          require_relative "../../mirror"
          require_relative "../docbook_mirror"
          mirror_output = Docbook::Output::DocbookMirror.new(
            context.parsed, sort_glossary: context.sort_glossary
          )
          mirror_data = mirror_output.to_document.to_h

          guide.merge!(mirror_data)
          guide
        end
      end
    end
  end
end
