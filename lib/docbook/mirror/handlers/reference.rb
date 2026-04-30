# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Reference
        def self.reference(element, context:)
          attrs = {
            xml_id: element.xml_id || "elem-#{element.object_id}",
            title: element.title&.content&.join || element.info&.title&.then { |t| t&.content&.join },
          }.compact

          content = []

          # refentry is a mapped attribute, not mixed content
          if element.respond_to?(:refentry)
            element.refentry.each do |re|
              entry = refentry(re, context: context)
              content << entry if entry
            end
          end

          content.concat(context.extract_content(element))
          Node::Reference.new(attrs: attrs, content: content)
        end

        def self.refentry(element, context:)
          title = context.resolve_refentry_title(element)
          id = context.refentry_id(element)

          attrs = {
            xml_id: id,
            title: title,
          }.compact

          content = []

          # Build synopsis from refmeta
          if element.refmeta
            if element.refmeta.fieldsynopsis && !element.refmeta.fieldsynopsis.empty?
              fs = element.refmeta.fieldsynopsis.first
              parts = []
              if fs.type && !fs.type.content.join.empty?
                parts << Node::Text.new(
                  text: fs.type.content.join, marks: [Mark::Code.new(role: "type")],
                )
              end
              parts << Node::Text.new(text: " ")
              if fs.varname && !fs.varname.content.join.empty?
                parts << Node::Text.new(
                  text: fs.varname.content.join, marks: [Mark::Code.new(role: "varname")],
                )
              end
              if fs.initializer && !fs.initializer.content.join.empty?
                parts << Node::Text.new(text: " = ")
                parts << Node::Text.new(
                  text: fs.initializer.content.join, marks: [Mark::Code.new(role: "literal")],
                )
              end
              unless parts.empty?
                content << Node::Paragraph.new(
                  attrs: { class: "refmeta-synopsis" },
                  content: parts,
                )
              end
            elsif element.refmeta.refentrytitle
              synopsis_parts = []
              reftitle = element.refmeta.refentrytitle.content.join
              manvol = element.refmeta.manvolnum
              synopsis_parts << "#{reftitle}(#{manvol})" if reftitle && manvol
              synopsis_parts << reftitle.to_s if reftitle && !manvol
              Array(element.refmeta.refmiscinfo).each do |info|
                synopsis_parts << info.content.join if info.content.any?
              end
              unless synopsis_parts.empty?
                content << Node::Paragraph.new(
                  content: [Node::Text.new(
                    text: synopsis_parts.join(" — "),
                    marks: [Mark::Code.new],
                  )],
                )
              end
            end
          end

          # refnamediv is a mapped attribute, not mixed content — process explicitly
          if element.respond_to?(:refnamediv) && element.refnamediv
            content.concat(refnamediv(element.refnamediv, context: context))
          end

          content.concat(context.extract_content(element))
          Node::RefEntry.new(attrs: attrs, content: content)
        end

        def self.refnamediv(element, context:)
          content = []

          # Render refnames (e.g. "$v:as-json")
          names = Array(element.refname).filter_map { |r| r.content.join }
          unless names.empty?
            content << Node::Paragraph.new(
              content: [Node::Text.new(
                text: names.join(", "),
                marks: [Mark::Code.new],
              )],
            )
          end

          # Render refpurpose
          if element.refpurpose&.content&.any?
            content << Node::Paragraph.new(
              attrs: { class: "refpurpose" },
              content: [Node::Text.new(text: element.refpurpose.content.join)],
            )
          end

          # Render refclass as a badge
          if element.refclass&.content&.any?
            content << Node::Paragraph.new(
              attrs: { class: "refclass" },
              content: [Node::Text.new(
                text: element.refclass.content.join,
                marks: [Mark::Code.new(role: "refclass")],
              )],
            )
          end

          content
        end

        def self.refsection(element, context:)
          title = element.title&.content&.join
          id = element.xml_id || "elem-#{element.object_id}"
          attrs = { xml_id: id, title: title }.compact

          content = context.extract_content(element)
          Node::RefSection.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
