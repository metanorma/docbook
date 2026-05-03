# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Annotation
        def self.call(element, context:)
          attrs = { xml_id: element.xml_id }.compact
          content = []
          if element.para&.any?
            element.para.filter_map do |p|
              context.paragraph_handler(p)
            end.each { |n| content << n }
          else
            text = context.extract_text(element)
            content << context.text_node(text) unless text.empty?
          end
          return nil if content.empty?

          Node.new(type: "annotation", attrs: attrs, content: content)
        end
      end
    end
  end
end
