# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Section
        def self.resolve_title(el)
          el.title&.content&.join ||
            (el.info&.title&.content&.join if el.respond_to?(:info))
        end

        def self.section(el, context:)
          attrs = {
            number: el.number,
            title: resolve_title(el),
            xml_id: el.xml_id || "elem-#{el.object_id}",
          }.compact

          content = context.extract_content(el)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Section.new(attrs: attrs, content: content)
        end

        def self.chapter(el, context:)
          attrs = {
            number: el.number,
            title: resolve_title(el),
            xml_id: el.xml_id || "elem-#{el.object_id}",
          }.compact

          content = context.extract_content(el)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Chapter.new(attrs: attrs, content: content)
        end

        def self.appendix(el, context:)
          attrs = {
            number: el.number,
            title: resolve_title(el),
            xml_id: el.xml_id || "elem-#{el.object_id}",
          }.compact

          content = context.extract_content(el)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Appendix.new(attrs: attrs, content: content)
        end

        def self.part(el, context:)
          id = el.xml_id || "elem-#{el.object_id}"
          attrs = {
            number: el.number,
            title: resolve_title(el),
            xml_id: id,
          }.compact

          content = context.extract_content(el)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Part.new(attrs: attrs, content: content)
        end

        def self.simplesect(el, context:)
          content = context.extract_content(el)
          title = resolve_title(el) if el.respond_to?(:title)

          attrs = { title: title }.compact
          Node::Section.new(attrs: attrs, content: content)
        end

        def self.sect(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: resolve_title(el),
          }.compact
          content = context.extract_content(el)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Section.new(attrs: attrs, content: content)
        end

        def self.preface(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: resolve_title(el),
          }.compact
          content = context.extract_content(el)
          fn = context.flush_footnotes
          content << fn if fn
          Node::Preface.new(attrs: attrs, content: content)
        end

        def self.titled_section(el, context:, node_class:)
          attrs = {
            xml_id: el.xml_id,
            title: resolve_title(el),
          }.compact
          content = context.extract_content(el)
          node_class.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
