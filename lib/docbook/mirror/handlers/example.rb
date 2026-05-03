# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Example
        def self.call(element, context:)
          title_text = context.resolve_title(element)
          xml_id = element.xml_id
          attrs = { xml_id: xml_id, title: title_text }.compact

          content = context.extract_content(element)

          return nil if content.empty? && !xml_id

          Node::CodeBlock.new(
            attrs: attrs,
            content: content,
          )
        end

        def self.informal(element, context:)
          inner = context.extract_content(element)
          return nil if inner.empty?

          xml_id = element.xml_id
          return inner.first if inner.length == 1 && !xml_id

          Node::CodeBlock.new(attrs: { xml_id: xml_id }.compact, content: inner)
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
            title: context.resolve_title(element),
          }.compact
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Section.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
