# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class CodeBlock
        def self.call(el, context:, language: nil)
          language ||= el.language if el.respond_to?(:language)

          # Check for <co> callout markers in the code block
          co_markers = context.extract_co_markers(el)
          text = context.extract_text_with_callouts(el, co_markers)
          return nil if text.empty?

          attrs = { language: language }.compact
          attrs[:callouts] = co_markers if co_markers.any?

          Node::CodeBlock.new(
            attrs: attrs,
            content: [Node::Text.new(text: text)],
          )
        end
      end
    end
  end
end
