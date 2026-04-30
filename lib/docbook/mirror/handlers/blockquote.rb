# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Blockquote
        def self.call(el, context:)
          content = context.extract_content(el)
          return nil if content.empty?

          Node::Blockquote.new(content: content)
        end
      end
    end
  end
end
