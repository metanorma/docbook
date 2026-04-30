# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Media
        # Figure and InformalFigure
        def self.figure(el, context:)
          title_text = el.title&.content&.join if el.respond_to?(:title)
          xml_id = el.xml_id

          # Check for programlisting/screen content first (code figures)
          code_el = nil
          if el.respond_to?(:programlisting) && el.programlisting
            code_el = el.programlisting
          elsif el.respond_to?(:screen) && el.screen
            code_el = el.screen
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
          if el.respond_to?(:mediaobject) && el.mediaobject && !el.mediaobject.empty?
            media = el.mediaobject.first
          elsif el.respond_to?(:imageobject) && el.imageobject && !el.imageobject.empty?
            media = el
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
        def self.inline_image(el, context:)
          href = el.imageobject&.first&.imagedata&.fileref if el.respond_to?(:imageobject)
          Node::Image.new(attrs: { src: href }.compact)
        end
      end
    end
  end
end
