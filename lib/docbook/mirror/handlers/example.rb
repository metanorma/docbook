# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Example
        def self.call(element, context:)
          title_text = element.title&.content&.join if element.respond_to?(:title)
          xml_id = element.xml_id
          attrs = { xml_id: xml_id, title: title_text }.compact

          content = context.extract_content(element)

          # Always emit if we have an xml_id (needed for xref targets)
          # even if content is empty
          return nil if content.empty? && !xml_id

          Node::CodeBlock.new(
            attrs: attrs,
            content: content,
          )
        end

        def self.informal(element, context:)
          inner = context.extract_content(element)
          return nil if inner.empty?

          xml_id = element.xml_id if element.respond_to?(:xml_id)
          return inner.first if inner.length == 1 && !xml_id

          attrs = { xml_id: xml_id }.compact
          Node::CodeBlock.new(attrs: attrs, content: inner)
        end

        def self.address(element, context:)
          attrs = { xml_id: element.xml_id }.compact
          text = context.extract_text(element)
          return nil if text.empty?

          Node::CodeBlock.new(
            attrs: attrs.merge({ language: "text" }),
            content: [Node::Text.new(text: text)],
          )
        end

        def self.legalnotice(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Section.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
