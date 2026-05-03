# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Equation
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          content = context.extract_content(element)
          return nil if content.empty? && !element.xml_id

          # Extract image from mediaobject if present
          if content.empty? && element.mediaobject.any?
            img = Handlers::Media.figure(element, context: context)
            content << img if img
          end

          Node::Equation.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
