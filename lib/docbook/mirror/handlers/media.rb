# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Media
        # Figure and InformalFigure
        def self.figure(element, context:)
          title_text = element.title&.content&.join if element.respond_to?(:title)
          xml_id = element.xml_id

          # Check for programlisting/screen content first (code figures)
          code_el = nil
          if element.respond_to?(:programlisting) && element.programlisting
            code_el = element.programlisting
          elsif element.respond_to?(:screen) && element.screen
            code_el = element.screen
          end

          if code_el
            lang = code_el.respond_to?(:language) ? code_el.language : nil
            code_text = context.extract_text(code_el)
            attrs = { xml_id: xml_id, title: title_text, language: lang }.compact
            return Node::CodeBlock.new(
              attrs: attrs,
              content: [Node::Text.new(text: code_text)],
            )
          end

          # Figure has mediaobject (collection), InformalFigure also has mediaobject
          # Both contain imageobject with imagedata.fileref
          media = nil
          if element.respond_to?(:mediaobject) && element.mediaobject && !element.mediaobject.empty?
            media = element.mediaobject.first
          elsif element.respond_to?(:imageobject) && element.imageobject && !element.imageobject.empty?
            media = element
          end

          image_obj = media&.imageobject&.first if media.respond_to?(:imageobject)
          href = image_obj&.imagedata&.fileref if image_obj.respond_to?(:imagedata)

          # Emit placeholder with xml_id even without image, for xref anchoring
          unless href
            return nil unless xml_id

            attrs = { xml_id: xml_id, title: title_text }.compact
            return Node::Paragraph.new(
              attrs: attrs,
              content: [Node::Text.new(text: "[#{title_text || xml_id}]")],
            )
          end
          attrs = { xml_id: xml_id, title: title_text, src: href }.compact
          Node::Image.new(attrs: attrs)
        end

        # Inline image from Inlinemediaobject
        def self.inline_image(element, context:)
          href = element.imageobject&.first&.then { |io| io&.imagedata&.fileref } if element.respond_to?(:imageobject)
          Node::Image.new(attrs: { src: href }.compact)
        end
      end
    end
  end
end
