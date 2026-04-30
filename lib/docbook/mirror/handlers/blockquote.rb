# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Blockquote
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Blockquote.new(content: content)
        end
      end
    end
  end
end
