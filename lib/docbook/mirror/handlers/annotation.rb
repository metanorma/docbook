# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Annotation
        def self.call(el, context:)
          attrs = { xml_id: el.xml_id }.compact
          content = []
          if el.respond_to?(:para) && el.para&.any?
            el.para.filter_map { |p| context.paragraph_handler(p) }.each { |n| content << n }
          else
            text = context.extract_text(el)
            content << context.text_node(text) unless text.empty?
          end
          return nil if content.empty?

          Node.new(type: "annotation", attrs: attrs, content: content)
        end
      end
    end
  end
end
