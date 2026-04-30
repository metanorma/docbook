# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Sidebar
        def self.call(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          content = context.extract_content(el)
          return nil if content.empty?

          Node::Sidebar.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
