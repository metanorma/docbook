# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Structural
        def self.set(element, context:)
          title = context.resolve_title(element)
          attrs = {
            xml_id: element.xml_id,
            title: title,
          }.compact
          content = context.extract_content(element)
          Node::Set.new(attrs: attrs, content: content)
        end

        def self.topic(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          content = context.extract_content(element)
          Node::Topic.new(attrs: attrs, content: content)
        end

        def self.article(element, context:)
          context.document_node(element)
        end
      end
    end
  end
end
