# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Structural
        def self.set(element, context:)
          title = element.title&.content&.join || (element.info&.title&.then { |t| t&.content&.join } if element.respond_to?(:info))
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
            title: element.title&.content&.join,
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
