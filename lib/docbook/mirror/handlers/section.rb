# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Section
        def self.resolve_title(element)
          element.title&.content&.join ||
            (element.info&.title&.then { |t| t&.content&.join } if element.respond_to?(:info))
        end

        def self.section(element, context:)
          attrs = {
            number: element.number,
            title: resolve_title(element),
            xml_id: element.xml_id || "elem-#{element.object_id}",
          }.compact

          content = context.extract_content(element)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Section.new(attrs: attrs, content: content)
        end

        def self.chapter(element, context:)
          attrs = {
            number: element.number,
            title: resolve_title(element),
            xml_id: element.xml_id || "elem-#{element.object_id}",
          }.compact

          content = context.extract_content(element)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Chapter.new(attrs: attrs, content: content)
        end

        def self.appendix(element, context:)
          attrs = {
            number: element.number,
            title: resolve_title(element),
            xml_id: element.xml_id || "elem-#{element.object_id}",
          }.compact

          content = context.extract_content(element)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Appendix.new(attrs: attrs, content: content)
        end

        def self.part(element, context:)
          id = element.xml_id || "elem-#{element.object_id}"
          attrs = {
            number: element.number,
            title: resolve_title(element),
            xml_id: id,
          }.compact

          content = context.extract_content(element)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Part.new(attrs: attrs, content: content)
        end

        def self.simplesect(element, context:)
          content = context.extract_content(element)
          title = resolve_title(element) if element.respond_to?(:title)

          attrs = { title: title }.compact
          Node::Section.new(attrs: attrs, content: content)
        end

        def self.sect(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: resolve_title(element),
          }.compact
          content = context.extract_content(element)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Section.new(attrs: attrs, content: content)
        end

        def self.preface(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: resolve_title(element),
          }.compact
          content = context.extract_content(element)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Preface.new(attrs: attrs, content: content)
        end

        def self.titled_section(element, context:, node_class:)
          attrs = {
            xml_id: element.xml_id,
            title: resolve_title(element),
          }.compact
          content = context.extract_content(element)
          node_class.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
