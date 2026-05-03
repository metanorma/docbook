# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Section
        def self.section(element, context:)
          build_section_node(element, context, node_class: Node::Section)
        end

        def self.chapter(element, context:)
          build_section_node(element, context, node_class: Node::Chapter,
                                               attrs: { number: element.number })
        end

        def self.appendix(element, context:)
          build_section_node(element, context, node_class: Node::Appendix,
                                               attrs: { number: element.number })
        end

        def self.part(element, context:)
          build_section_node(element, context, node_class: Node::Part,
                                               attrs: { number: element.number })
        end

        def self.simplesect(element, context:)
          content = context.extract_content(element)
          title = context.resolve_title(element)
          Node::Section.new(attrs: { title: title }.compact, content: content)
        end

        def self.sect(element, context:)
          build_section_node(element, context, node_class: Node::Section)
        end

        def self.preface(element, context:)
          build_section_node(element, context, node_class: Node::Preface,
                                               skip_footnotes: true)
        end

        def self.titled_section(element, context:, node_class:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          content = context.extract_content(element)
          node_class.new(attrs: attrs, content: content)
        end

        class << self
          private

          def build_section_node(element, context, node_class:, attrs: {},
skip_footnotes: false)
            base_attrs = {
              xml_id: element.xml_id || "elem-#{element.object_id}",
              title: context.resolve_title(element),
            }.compact.merge(attrs)
            content = context.extract_content(element)
            fn = context.flush_footnotes unless skip_footnotes
            content << fn if fn
            node_class.new(attrs: base_attrs, content: content)
          end
        end
      end
    end
  end
end
