# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Example
        def self.call(el, context:)
          title_text = el.title&.content&.join if el.respond_to?(:title)
          xml_id = el.xml_id
          attrs = { xml_id: xml_id, title: title_text }.compact

          content = context.extract_content(el)

          # Always emit if we have an xml_id (needed for xref targets)
          # even if content is empty
          return nil if content.empty? && !xml_id

          Node::CodeBlock.new(
            attrs: attrs,
            content: content,
          )
        end

        def self.informal(el, context:)
          inner = context.extract_content(el)
          return nil if inner.empty?

          xml_id = el.xml_id if el.respond_to?(:xml_id)
          return inner.first if inner.length == 1 && !xml_id

          attrs = { xml_id: xml_id }.compact
          Node::CodeBlock.new(attrs: attrs, content: inner)
        end

        def self.address(el, context:)
          attrs = { xml_id: el.xml_id }.compact
          text = context.extract_text(el)
          return nil if text.empty?

          Node::CodeBlock.new(
            attrs: attrs.merge({ language: "text" }),
            content: [Node::Text.new(text: text)],
          )
        end

        def self.legalnotice(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          content = context.extract_content(el)
          return nil if content.empty?

          Node::Section.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
