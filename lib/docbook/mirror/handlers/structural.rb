# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Structural
        def self.set(el, context:)
          title = el.title&.content&.join || (el.info&.title&.content&.join if el.respond_to?(:info))
          attrs = {
            xml_id: el.xml_id,
            title: title,
          }.compact
          content = context.extract_content(el)
          Node::Set.new(attrs: attrs, content: content)
        end

        def self.topic(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          content = context.extract_content(el)
          Node::Topic.new(attrs: attrs, content: content)
        end

        def self.article(el, context:)
          context.document_node(el)
        end
      end
    end
  end
end
