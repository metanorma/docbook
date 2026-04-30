# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Reference
        def self.reference(el, context:)
          attrs = {
            xml_id: el.xml_id || "elem-#{el.object_id}",
            title: el.title&.content&.join || el.info&.title&.content&.join,
          }.compact

          content = []

          # refentry is a mapped attribute, not mixed content
          if el.respond_to?(:refentry)
            el.refentry.each do |re|
              entry = refentry(re, context: context)
              content << entry if entry
            end
          end

          content.concat(context.extract_content(el))
          Node::Reference.new(attrs: attrs, content: content)
        end

        def self.refentry(el, context:)
          title = context.resolve_refentry_title(el)
          id = context.refentry_id(el)

          attrs = {
            xml_id: id,
            title: title,
          }.compact

          content = []

          # Build synopsis from refmeta
          if el.refmeta
            if el.refmeta.fieldsynopsis && !el.refmeta.fieldsynopsis.empty?
              fs = el.refmeta.fieldsynopsis.first
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
            elsif el.refmeta.refentrytitle
              synopsis_parts = []
              reftitle = el.refmeta.refentrytitle.content.join
              manvol = el.refmeta.manvolnum
              synopsis_parts << "#{reftitle}(#{manvol})" if reftitle && manvol
              synopsis_parts << reftitle.to_s if reftitle && !manvol
              Array(el.refmeta.refmiscinfo).each do |info|
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
          if el.respond_to?(:refnamediv) && el.refnamediv
            content.concat(refnamediv(el.refnamediv, context: context))
          end

          content.concat(context.extract_content(el))
          Node::RefEntry.new(attrs: attrs, content: content)
        end

        def self.refnamediv(el, context:)
          content = []

          # Render refnames (e.g. "$v:as-json")
          names = Array(el.refname).filter_map { |r| r.content.join }
          unless names.empty?
            content << Node::Paragraph.new(
              content: [Node::Text.new(
                text: names.join(", "),
                marks: [Mark::Code.new],
              )],
            )
          end

          # Render refpurpose
          if el.refpurpose&.content&.any?
            content << Node::Paragraph.new(
              attrs: { class: "refpurpose" },
              content: [Node::Text.new(text: el.refpurpose.content.join)],
            )
          end

          # Render refclass as a badge
          if el.refclass&.content&.any?
            content << Node::Paragraph.new(
              attrs: { class: "refclass" },
              content: [Node::Text.new(
                text: el.refclass.content.join,
                marks: [Mark::Code.new(role: "refclass")],
              )],
            )
          end

          content
        end

        def self.refsection(el, context:)
          title = el.title&.content&.join
          id = el.xml_id || "elem-#{el.object_id}"
          attrs = { xml_id: id, title: title }.compact

          content = context.extract_content(el)
          Node::RefSection.new(attrs: attrs, content: content)
        end
      end
    end
  end
end
