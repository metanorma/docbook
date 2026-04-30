# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Equation
        def self.call(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          content = context.extract_content(el)
          return nil if content.empty? && !el.xml_id

          # Extract image from mediaobject if present
          if content.empty? && el.respond_to?(:mediaobject) && el.mediaobject.any?
            img = Handlers::Media.figure(el, context: context)
            content << img if img
          end

          Node::Equation.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
