# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Paragraph
        def self.call(el, context:)
          content = context.process_inline_content(el)
          return nil if content.empty?

          Node::Paragraph.new(content: content)
        end
      end
    end
  end
end
