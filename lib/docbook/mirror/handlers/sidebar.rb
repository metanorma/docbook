# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Sidebar
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Sidebar.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
