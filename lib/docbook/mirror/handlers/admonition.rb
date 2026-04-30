# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Admonition
        def self.call(element, context:)
          type = element.class.name.split("::").last.downcase
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Admonition.new(
            attrs: { admonition_type: type },
            content: content,
          )
        end
      end
    end
  end
end
