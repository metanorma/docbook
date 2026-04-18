# frozen_string_literal: true

require "uri"

module Docbook
  module Mirror
    class Transformer
      include Docbook::Services::ElementIdHelper

      def initialize(sort_glossary: false)
        @xml_id_map = {}
        @footnote_counter = 0
        @footnotes = []
        @sort_glossary = sort_glossary
      end

      # Entry point: Convert DocBook document to DocbookMirror
      def from_docbook(docbook_doc)
        @xml_id_map = build_xml_id_map(docbook_doc)
        @footnote_counter = 0
        @footnotes = []
        document_node(docbook_doc)
      end

      private

      # =========================================
      # Document Structure
      # =========================================

      def document_node(docbook_doc)
        title = if docbook_doc.respond_to?(:info) && docbook_doc.info.respond_to?(:title)
                  docbook_doc.info.title&.content
                elsif docbook_doc.respond_to?(:title)
                  docbook_doc.title&.content
                end

        attrs = { title: title }.compact

        content = extract_content(docbook_doc)

        Docbook::Mirror::Node::Document.new(attrs: attrs, content: content)
      end

      def extract_content(element)
        content = []
        return content unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          case node
          when String
            next if node.strip.empty?
          when Docbook::Elements::Para
            content << paragraph_node(node)
          when Docbook::Elements::FormalPara
            content << paragraph_node(node.para) if node.para
          when Docbook::Elements::Code, Docbook::Elements::ProgramListing
            content << code_block_node(node)
          when Docbook::Elements::Screen
            content << code_block_node(node, language: "text")
          when Docbook::Elements::LiteralLayout
            content << code_block_node(node, language: "text")
          when Docbook::Elements::BlockQuote
            content << blockquote_node(node)
          when Docbook::Elements::OrderedList
            content << ordered_list_node(node)
          when Docbook::Elements::ItemizedList
            content << bullet_list_node(node)
          when Docbook::Elements::VariableList
            content << definition_list_node(node)
          when Docbook::Elements::Figure, Docbook::Elements::InformalFigure
            content << figure_node(node)
          when Docbook::Elements::Example
            content << example_node(node)
          when Docbook::Elements::Table, Docbook::Elements::InformalTable
            content << table_node(node)
          when Docbook::Elements::Note, Docbook::Elements::Warning,
               Docbook::Elements::Tip, Docbook::Elements::Caution,
               Docbook::Elements::Important, Docbook::Elements::Danger
            content << admonition_node(node)
          when Docbook::Elements::Simplesect
            content << simplesect_node(node)
          when Docbook::Elements::Section
            content << section_node(node)
          when Docbook::Elements::Chapter
            content << chapter_node(node)
          when Docbook::Elements::Appendix
            content << appendix_node(node)
          when Docbook::Elements::Part
            content << part_node(node)
          when Docbook::Elements::Reference
            content << reference_node(node)
          when Docbook::Elements::RefEntry
            content << refentry_node(node)
          when Docbook::Elements::RefNamediv
            content.concat(refnamediv_node(node))
          when Docbook::Elements::RefSection, Docbook::Elements::RefSect1,
               Docbook::Elements::RefSect2, Docbook::Elements::RefSect3
            content << refsection_node(node)
          when Docbook::Elements::InformalExample
            content << informal_example_node(node)
          when Docbook::Elements::Annotation
            content << annotation_node(node)
          when Docbook::Elements::QandASet
            content << qandaset_node(node)
          else
            dispatch_content_node(node, content)
          end
        end
        content.compact
      end

      def dispatch_content_node(node, content)
        case node
        when Docbook::Elements::Preface
          content << preface_node(node)
        when Docbook::Elements::Dedication
          content << titled_section_node(node, Node::Preface)
        when Docbook::Elements::Acknowledgements
          content << titled_section_node(node, Node::Acknowledgements)
        when Docbook::Elements::Colophon
          content << titled_section_node(node, Node::Colophon)
        when Docbook::Elements::Glossary
          content << glossary_node(node)
        when Docbook::Elements::Bibliography
          content << bibliography_node(node)
        when Docbook::Elements::Index, Docbook::Elements::SetIndex
          content << index_node(node)
        when Docbook::Elements::Bibliolist
          content << bibliolist_node(node)
        when Docbook::Elements::Equation
          content << equation_node(node)
        when Docbook::Elements::Procedure
          content << procedure_node(node)
        when Docbook::Elements::CalloutList
          content << calloutlist_node(node)
        when Docbook::Elements::SideBar
          content << sidebar_node(node)
        when Docbook::Elements::Address
          content << address_node(node)
        when Docbook::Elements::LegalNotice
          content << legalnotice_node(node)
        when Docbook::Elements::Set
          content << set_node(node)
        when Docbook::Elements::Article
          content << document_node(node)
        when Docbook::Elements::Topic
          content << topic_node(node)
        when Docbook::Elements::Sect1, Docbook::Elements::Sect2,
             Docbook::Elements::Sect3, Docbook::Elements::Sect4,
             Docbook::Elements::Sect5
          content << sect_node(node)
        end
      end

      # =========================================
      # Block Nodes
      # =========================================

      def paragraph_node(para)
        content = process_inline_content(para)
        return nil if content.empty?

        Docbook::Mirror::Node::Paragraph.new(content: content)
      end

      def code_block_node(el, language: nil)
        language ||= el.language if el.respond_to?(:language)

        # Check for <co> callout markers in the code block
        co_markers = extract_co_markers(el)
        text = extract_text_with_callouts(el, co_markers)
        return nil if text.empty?

        attrs = { language: language }.compact
        attrs[:callouts] = co_markers if co_markers.any?

        Docbook::Mirror::Node::CodeBlock.new(
          attrs: attrs,
          content: [Docbook::Mirror::Node::Text.new(text: text)],
        )
      end

      def blockquote_node(el)
        content = extract_content(el)
        return nil if content.empty?

        Docbook::Mirror::Node::Blockquote.new(content: content)
      end

      def ordered_list_node(el)
        items = el.listitem.to_a.filter_map { |li| list_item_node(li) }
        return nil if items.empty?

        Docbook::Mirror::Node::OrderedList.new(content: items)
      end

      def bullet_list_node(el)
        items = el.listitem.to_a.filter_map { |li| list_item_node(li) }
        return nil if items.empty?

        Docbook::Mirror::Node::BulletList.new(content: items)
      end

      def list_item_node(li)
        content = extract_content(li)
        return nil if content.empty?

        Docbook::Mirror::Node::ListItem.new(content: content)
      end

      def definition_list_node(vl)
        entries = vl.varlistentry.to_a.flat_map do |ve|
          definition_entry_node(ve)
        end
        return nil if entries.empty?

        Docbook::Mirror::Node::DefinitionList.new(content: entries)
      end

      def definition_entry_node(ve)
        term_node = term_node(ve)
        desc_node = desc_node(ve)
        return nil unless term_node || desc_node

        [term_node, desc_node].compact
      end

      def term_node(ve)
        return nil unless ve.respond_to?(:term)

        term_content = process_inline_content(ve.term) if ve.term
        return nil if term_content.empty?

        Docbook::Mirror::Node::DefinitionTerm.new(content: term_content)
      end

      def desc_node(ve)
        li = ve.listitem if ve.respond_to?(:listitem)
        return nil unless li

        desc_content = extract_content(li)

        return nil if desc_content.empty?

        Docbook::Mirror::Node::DefinitionDescription.new(content: desc_content)
      end

      def figure_node(el)
        title_text = el.title&.content if el.respond_to?(:title)
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
          code_text = extract_text(code_el)
          attrs = { xml_id: xml_id, title: title_text, language: lang }.compact
          return Docbook::Mirror::Node::CodeBlock.new(
            attrs: attrs,
            content: [Docbook::Mirror::Node::Text.new(text: code_text)],
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
          return Docbook::Mirror::Node::Paragraph.new(
            attrs: attrs,
            content: [Docbook::Mirror::Node::Text.new(text: "[#{title_text || xml_id}]")],
          )
        end
        attrs = { xml_id: xml_id, title: title_text, src: href }.compact
        Docbook::Mirror::Node::Image.new(attrs: attrs)
      end

      def table_node(el)
        attrs = {}
        attrs[:xml_id] = el.xml_id if el.respond_to?(:xml_id) && el.xml_id
        if el.respond_to?(:title) && el.title
          attrs[:title] =
            el.title.content.to_s
        end
        attrs[:frame] = el.frame if el.respond_to?(:frame) && el.frame
        attrs[:colsep] = el.colsep if el.respond_to?(:colsep) && el.colsep
        attrs[:rowsep] = el.rowsep if el.respond_to?(:rowsep) && el.rowsep

        table_content = []

        tgroups = el.respond_to?(:tgroup) ? el.tgroup : []
        tgroups.each do |tg|
          attrs[:cols] = tg.cols if tg.respond_to?(:cols) && tg.cols

          if tg.respond_to?(:thead) && tg.thead
            head_rows = build_table_rows(tg.thead.row)
            table_content << Docbook::Mirror::Node::TableHead.new(content: head_rows) unless head_rows.empty?
          end

          next unless tg.respond_to?(:tbody) && tg.tbody

          body_rows = build_table_rows(tg.tbody.row)
          table_content << Docbook::Mirror::Node::TableBody.new(content: body_rows) unless body_rows.empty?
        end

        Docbook::Mirror::Node::Table.new(attrs: attrs.compact,
                                         content: table_content)
      end

      def build_table_rows(rows)
        rows.map do |row|
          cells = row.entry.map do |entry|
            cell_content = []
            text = entry.content.to_s.strip
            cell_content << Docbook::Mirror::Node::Text.new(text: text) unless text.empty?
            cell_attrs = {}
            cell_attrs[:align] = entry.align if entry.align
            cell_attrs[:valign] = entry.valign if entry.valign
            cell_attrs[:namest] = entry.namest if entry.namest
            cell_attrs[:nameend] = entry.nameend if entry.nameend
            cell_attrs[:morerows] = entry.morerows if entry.morerows
            Docbook::Mirror::Node::TableCell.new(attrs: cell_attrs.compact,
                                                 content: cell_content)
          end
          Docbook::Mirror::Node::TableRow.new(content: cells)
        end
      end

      def example_node(el)
        title_text = el.title&.content if el.respond_to?(:title)
        xml_id = el.xml_id
        attrs = { xml_id: xml_id, title: title_text }.compact

        content = extract_content(el)

        # Always emit if we have an xml_id (needed for xref targets)
        # even if content is empty
        return nil if content.empty? && !xml_id

        Docbook::Mirror::Node::CodeBlock.new(
          attrs: attrs,
          content: content,
        )
      end

      def informal_example_node(el)
        inner = extract_content(el)
        return nil if inner.empty?

        xml_id = el.xml_id if el.respond_to?(:xml_id)
        return inner.first if inner.length == 1 && !xml_id

        attrs = { xml_id: xml_id }.compact
        Docbook::Mirror::Node::CodeBlock.new(attrs: attrs, content: inner)
      end

      def admonition_node(el)
        type = el.class.name.split("::").last.downcase
        content = extract_content(el)
        return nil if content.empty?

        Docbook::Mirror::Node::Admonition.new(
          attrs: { admonition_type: type },
          content: content,
        )
      end

      def simplesect_node(el)
        content = extract_content(el)
        title = el.title&.content if el.respond_to?(:title)

        attrs = { title: title }.compact
        Docbook::Mirror::Node::Section.new(attrs: attrs, content: content)
      end

      def section_node(section)
        attrs = {
          number: section.number,
          title: section.title&.content,
          xml_id: section.xml_id || "elem-#{section.object_id}",
        }.compact

        content = extract_content(section)
        fn = flush_footnotes
        content << fn if fn
        Docbook::Mirror::Node::Section.new(attrs: attrs, content: content)
      end

      def chapter_node(chapter)
        attrs = {
          number: chapter.number,
          title: chapter.title&.content,
          xml_id: chapter.xml_id || "elem-#{chapter.object_id}",
        }.compact

        content = extract_content(chapter)
        fn = flush_footnotes
        content << fn if fn
        Docbook::Mirror::Node::Chapter.new(attrs: attrs, content: content)
      end

      def appendix_node(appendix)
        attrs = {
          number: appendix.number,
          title: appendix.title&.content,
          xml_id: appendix.xml_id || "elem-#{appendix.object_id}",
        }.compact

        content = extract_content(appendix)
        fn = flush_footnotes
        content << fn if fn
        Docbook::Mirror::Node::Appendix.new(attrs: attrs, content: content)
      end

      def part_node(part)
        id = part.xml_id || "elem-#{part.object_id}"
        attrs = {
          number: part.number,
          title: part.title&.content,
          xml_id: id,
        }.compact

        content = extract_content(part)
        fn = flush_footnotes
        content << fn if fn
        Docbook::Mirror::Node::Part.new(attrs: attrs, content: content)
      end

      def reference_node(ref)
        attrs = {
          xml_id: ref.xml_id || "elem-#{ref.object_id}",
          title: ref.title&.content || ref.info&.title&.content,
        }.compact

        content = extract_content(ref)
        Docbook::Mirror::Node::Reference.new(attrs: attrs, content: content)
      end

      def refentry_node(ref)
        title = resolve_refentry_title(ref)
        id = refentry_id(ref)

        attrs = {
          xml_id: id,
          title: title,
        }.compact

        content = []

        # Build synopsis from refmeta
        if ref.refmeta
          if ref.refmeta.fieldsynopsis && !ref.refmeta.fieldsynopsis.empty?
            fs = ref.refmeta.fieldsynopsis.first
            parts = []
            if fs.type && !fs.type.content.to_s.empty?
              parts << Docbook::Mirror::Node::Text.new(
                text: fs.type.content.to_s, marks: [Docbook::Mirror::Mark::Code.new(role: "type")],
              )
            end
            parts << Docbook::Mirror::Node::Text.new(text: " ")
            if fs.varname && !fs.varname.content.to_s.empty?
              parts << Docbook::Mirror::Node::Text.new(
                text: fs.varname.content.to_s, marks: [Docbook::Mirror::Mark::Code.new(role: "varname")],
              )
            end
            if fs.initializer && !fs.initializer.content.to_s.empty?
              parts << Docbook::Mirror::Node::Text.new(text: " = ")
              parts << Docbook::Mirror::Node::Text.new(
                text: fs.initializer.content.to_s, marks: [Docbook::Mirror::Mark::Code.new(role: "literal")],
              )
            end
            unless parts.empty?
              content << Docbook::Mirror::Node::Paragraph.new(
                attrs: { class: "refmeta-synopsis" },
                content: parts,
              )
            end
          elsif ref.refmeta.refentrytitle
            synopsis_parts = []
            reftitle = ref.refmeta.refentrytitle.content
            manvol = ref.refmeta.manvolnum
            synopsis_parts << "#{reftitle}(#{manvol})" if reftitle && manvol
            synopsis_parts << reftitle.to_s if reftitle && !manvol
            Array(ref.refmeta.refmiscinfo).each do |info|
              synopsis_parts << info.content.to_s if info.content
            end
            unless synopsis_parts.empty?
              content << Docbook::Mirror::Node::Paragraph.new(
                content: [Docbook::Mirror::Node::Text.new(
                  text: synopsis_parts.join(" — "),
                  marks: [Docbook::Mirror::Mark::Code.new],
                )],
              )
            end
          end
        end

        content.concat(extract_content(ref))
        Docbook::Mirror::Node::RefEntry.new(attrs: attrs, content: content)
      end

      def refnamediv_node(nd)
        content = []

        # Render refnames (e.g. "$v:as-json")
        names = Array(nd.refname).filter_map(&:content)
        unless names.empty?
          content << Docbook::Mirror::Node::Paragraph.new(
            content: [Docbook::Mirror::Node::Text.new(
              text: names.join(", "),
              marks: [Docbook::Mirror::Mark::Code.new],
            )],
          )
        end

        # Render refpurpose
        if nd.refpurpose&.content
          content << Docbook::Mirror::Node::Paragraph.new(
            attrs: { class: "refpurpose" },
            content: [Docbook::Mirror::Node::Text.new(text: nd.refpurpose.content)],
          )
        end

        # Render refclass as a badge
        if nd.refclass&.content
          content << Docbook::Mirror::Node::Paragraph.new(
            attrs: { class: "refclass" },
            content: [Docbook::Mirror::Node::Text.new(
              text: nd.refclass.content,
              marks: [Docbook::Mirror::Mark::Code.new(role: "refclass")],
            )],
          )
        end

        content
      end

      def refsection_node(rs)
        title = rs.title&.content
        id = rs.xml_id || "elem-#{rs.object_id}"
        attrs = { xml_id: id, title: title }.compact

        content = extract_content(rs)
        Docbook::Mirror::Node::RefSection.new(attrs: attrs, content: content)
      end

      # refentry_id and resolve_refentry_title provided by ElementIdHelper

      # =========================================
      # Inline Elements → Marks
      # =========================================

      def process_inline_content(element)
        return [] unless element.respond_to?(:each_mixed_content)

        children = []
        element.each_mixed_content do |node|
          case node
          when String
            # Preserve whitespace - only skip strings that are empty after stripping
            text = node
            children << Docbook::Mirror::Node::Text.new(text: text) unless text.empty?
          when Docbook::Elements::Emphasis
            children << emphasis_node(node)
          when Docbook::Elements::Literal, Docbook::Elements::Code,
               Docbook::Elements::UserInput, Docbook::Elements::ComputerOutput,
               Docbook::Elements::Filename, Docbook::Elements::ClassName,
               Docbook::Elements::Function, Docbook::Elements::Parameter,
               Docbook::Elements::Replaceable,
               Docbook::Elements::Command, Docbook::Elements::Option,
               Docbook::Elements::Envar, Docbook::Elements::Property,
               Docbook::Elements::Varname, Docbook::Elements::Type,
               Docbook::Elements::Errortype, Docbook::Elements::Errorcode,
               Docbook::Elements::Exceptionname, Docbook::Elements::Constant,
               Docbook::Elements::Prompt, Docbook::Elements::BuildTarget,
               Docbook::Elements::Enumvalue
            children << code_node(node)
          when Docbook::Elements::Link
            children << link_node(node)
          when Docbook::Elements::Xref
            children << xref_node(node)
          when Docbook::Elements::Quote
            children.concat(quote_node(node))
          when Docbook::Elements::Tag
            children << tag_node(node)
          when Docbook::Elements::Biblioref
            children << biblioref_node(node)
          when Docbook::Elements::FirstTerm, Docbook::Elements::Glossterm
            children << firstterm_node(node)
          when Docbook::Elements::Citetitle
            children << citetitle_node(node)
          when Docbook::Elements::Inlinemediaobject
            children << inline_image_node(node)
          when Docbook::Elements::ProductName
            children << productname_node(node)
          when Docbook::Elements::Trademark
            children << trademark_node(node)
          when Docbook::Elements::Email
            children << email_node(node)
          when Docbook::Elements::Uri
            children << uri_node(node)
          when Docbook::Elements::Subscript
            children << subscript_node(node)
          when Docbook::Elements::Superscript
            children << superscript_node(node)
          when Docbook::Elements::KeyCap
            children << keycap_node(node)
          when Docbook::Elements::Abbrev, Docbook::Elements::Phrase,
               Docbook::Elements::Application, Docbook::Elements::WordAsWord,
               Docbook::Elements::Date, Docbook::Elements::ReleaseInfo
            children << plain_text_node(node)
          when Docbook::Elements::CiterefEntry
            children << citerefentry_node(node)
          when Docbook::Elements::Footnote
            children << footnote_node(node)
          when Docbook::Elements::FootnoteRef
            children << footnoteref_node(node)
          else
            # Catch-all: try to extract text content from any unhandled inline element
            if node.respond_to?(:content) && node.content
              children << Docbook::Mirror::Node::Text.new(text: node.content.to_s)
            elsif node.respond_to?(:text) && node.text
              children << Docbook::Mirror::Node::Text.new(text: node.text.to_s)
            end
          end
        end
        children
      end

      def text_node(text, marks: [])
        Docbook::Mirror::Node::Text.new(text: text, marks: marks)
      end

      def emphasis_node(el)
        role = el.role
        mark = if %w[bold strong].include?(role)
                 Docbook::Mirror::Mark::Strong.new
               elsif role == "italic"
                 Docbook::Mirror::Mark::Italic.new
               else
                 Docbook::Mirror::Mark::Emphasis.new
               end
        text = el.content.to_s
        text_node(text, marks: [mark])
      end

      def code_node(el)
        role = code_role(el)
        text = extract_text(el)
        text_node(text, marks: [Docbook::Mirror::Mark::Code.new(role: role)])
      end

      def code_role(el)
        case el
        when Docbook::Elements::Literal then "literal"
        when Docbook::Elements::Code then "code"
        when Docbook::Elements::UserInput then "userinput"
        when Docbook::Elements::ComputerOutput then "computeroutput"
        when Docbook::Elements::Filename then "filename"
        when Docbook::Elements::ClassName then "classname"
        when Docbook::Elements::Function then "function"
        when Docbook::Elements::Parameter then "parameter"
        when Docbook::Elements::Replaceable then "replaceable"
        when Docbook::Elements::Command then "command"
        when Docbook::Elements::Option then "option"
        when Docbook::Elements::Envar then "envar"
        when Docbook::Elements::Property then "property"
        when Docbook::Elements::Varname then "varname"
        when Docbook::Elements::Type then "type"
        when Docbook::Elements::Errortype then "errortype"
        when Docbook::Elements::Errorcode then "errorcode"
        when Docbook::Elements::Exceptionname then "exceptionname"
        when Docbook::Elements::Constant then "constant"
        when Docbook::Elements::Prompt then "prompt"
        when Docbook::Elements::BuildTarget then "buildtarget"
        when Docbook::Elements::Enumvalue then "enumvalue"
        else "literal"
        end
      end

      def link_node(el)
        href = el.xlink_href&.to_s || (el.linkend ? "##{el.linkend}" : "#")

        # Handle self-closing links with no content
        if el.content.to_s.empty? && !has_inline_children(el)
          # For linkend references, resolve the title from xml_id_map
          if el.linkend
            text = @xml_id_map[el.linkend.to_s] || el.linkend.to_s
          else
            uri = begin
              URI(href)
            rescue StandardError
              nil
            end
            text = if uri&.path && !uri.path.empty? && uri.path != "/"
                     File.basename(uri.path)
                   elsif uri&.host
                     uri.host
                   else
                     href
                   end
          end
        else
          text = extract_text(el)
        end

        link_mark = if el.linkend
                      Docbook::Mirror::Mark::Link.new(linkend: el.linkend)
                    else
                      Docbook::Mirror::Mark::Link.new(href: href)
                    end

        text_node(text, marks: [link_mark])
      end

      def has_inline_children(el)
        return false unless el.respond_to?(:each_mixed_content)

        el.each_mixed_content do |node|
          return true if node.is_a?(Lutaml::Model::Serializable)
        end
        false
      end

      def xref_node(el)
        linkend = el.linkend.to_s
        resolved_title = @xml_id_map[linkend] || linkend
        text_node(
          resolved_title,
          marks: [Docbook::Mirror::Mark::Xref.new(linkend: linkend,
                                                  resolved: resolved_title)],
        )
      end

      def quote_node(el)
        # Quote can have nested inline elements - extract them
        children = []
        return children unless el.respond_to?(:each_mixed_content)

        el.each_mixed_content do |node|
          case node
          when String
            # Preserve whitespace - only skip empty strings
            text = node
            children << Docbook::Mirror::Node::Text.new(text: text) unless text.empty?
          when Docbook::Elements::Emphasis
            children << emphasis_node(node)
          when Docbook::Elements::Literal, Docbook::Elements::Code,
               Docbook::Elements::UserInput, Docbook::Elements::ComputerOutput,
               Docbook::Elements::Filename, Docbook::Elements::ClassName,
               Docbook::Elements::Function, Docbook::Elements::Parameter,
               Docbook::Elements::Replaceable
            children << code_node(node)
          when Docbook::Elements::Link
            children << link_node(node)
          when Docbook::Elements::Xref
            children << xref_node(node)
          when Docbook::Elements::Tag
            children << tag_node(node)
          when Docbook::Elements::Biblioref
            children << biblioref_node(node)
          when Docbook::Elements::FirstTerm, Docbook::Elements::Glossterm
            children << firstterm_node(node)
          end
        end
        children
      end

      def tag_node(el)
        tag_name = el.content.to_s
        text = "<#{tag_name}>"
        text_node(text, marks: [Docbook::Mirror::Mark::Code.new(role: "tag")])
      end

      def biblioref_node(el)
        linkend = el.linkend.to_s
        text = el.content.to_s.empty? ? linkend : el.content.to_s
        text_node(text,
                  marks: [Docbook::Mirror::Mark::Citation.new(bibref: linkend)])
      end

      def firstterm_node(el)
        text = extract_text(el)
        text_node(text, marks: [Docbook::Mirror::Mark::Emphasis.new])
      end

      def citetitle_node(el)
        text = el.content.to_s
        text_node(text,
                  marks: [Docbook::Mirror::Mark::Citation.new(bibref: el.href)])
      end

      def inline_image_node(el)
        href = el.imageobject&.first&.imagedata&.fileref if el.respond_to?(:imageobject)
        Docbook::Mirror::Node::Image.new(attrs: { src: href }.compact)
      end

      def productname_node(el)
        text = el.content.to_s
        suffix = case el.class_name
                 when "trade" then "\u2122"
                 when "registered" then "\u00AE"
                 when "copyright" then "\u00A9"
                 when "service" then "\u2120"
                 else ""
                 end
        full_text = text + suffix
        if el.href
          text_node(full_text,
                    marks: [Docbook::Mirror::Mark::Link.new(attrs: { href: el.href })])
        else
          text_node(full_text, marks: [Docbook::Mirror::Mark::Strong.new])
        end
      end

      def trademark_node(el)
        text = el.content.to_s
        suffix = case el.class_name
                 when "trade" then "\u2122"
                 when "registered" then "\u00AE"
                 when "copyright" then "\u00A9"
                 when "service" then "\u2120"
                 else "\u2122"
                 end
        text_node(text + suffix)
      end

      def email_node(el)
        text = el.content.to_s
        text_node(text,
                  marks: [Docbook::Mirror::Mark::Link.new(href: "mailto:#{text}")])
      end

      def uri_node(el)
        text = el.content.to_s
        text_node(text, marks: [Docbook::Mirror::Mark::Link.new(href: text)])
      end

      def subscript_node(el)
        text = el.content.to_s
        text_node(text, marks: [Docbook::Mirror::Mark.new(type: "subscript")])
      end

      def superscript_node(el)
        text = el.content.to_s
        text_node(text, marks: [Docbook::Mirror::Mark.new(type: "superscript")])
      end

      def keycap_node(el)
        text = el.content.to_s
        text_node(text,
                  marks: [Docbook::Mirror::Mark::Code.new(role: "keycap")])
      end

      def plain_text_node(el)
        text = el.content.to_s
        text_node(text)
      end

      def citerefentry_node(el)
        title = el.refentrytitle&.content.to_s
        manvol = el.manvolnum&.content.to_s
        text = manvol.empty? ? title : "#{title}(#{manvol})"
        text_node(text)
      end

      def footnote_node(el)
        @footnote_counter += 1
        num = @footnote_counter
        fn_id = "fn-#{num}"
        ref_id = "fn-ref-#{num}"

        # Collect footnote content
        fn_content = if el.respond_to?(:para) && el.para.any?
                        el.para.filter_map { |p| paragraph_node(p) }
                     elsif el.respond_to?(:each_mixed_content)
                        process_inline_content(el)
                     else
                        [text_node(extract_text(el))]
                     end

        @footnotes << {
          id: fn_id,
          ref_id: ref_id,
          number: num,
          xml_id: el.xml_id,
          content: fn_content,
        }

        # Return a footnote_marker node
        Node.new(
          type: "footnote_marker",
          attrs: { id: fn_id, ref_id: ref_id, number: num },
        )
      end

      def flush_footnotes
        return nil if @footnotes.empty?

        entries = @footnotes.map do |fn|
          Node.new(
            type: "footnote_entry",
            attrs: { id: fn[:id], ref_id: fn[:ref_id], number: fn[:number] },
            content: fn[:content],
          )
        end

        @footnotes = []
        Node.new(type: "footnotes", content: entries)
      end

      def footnoteref_node(el)
        # Find the referenced footnote in our collected footnotes
        linkend = el.linkend if el.respond_to?(:linkend)
        ref_fn = @footnotes.find { |fn| fn[:xml_id] == linkend } if linkend

        if ref_fn
          # Reuse the same footnote number
          Node.new(
            type: "footnote_marker",
            attrs: { id: ref_fn[:id], ref_id: "fn-ref-#{ref_fn[:number]}-dup-#{@footnote_counter}", number: ref_fn[:number] },
          )
        else
          # Can't resolve, render as text
          text_node("[footnote]")
        end
      end

      def annotation_node(el)
        attrs = { xml_id: el.xml_id }.compact
        content = []
        if el.respond_to?(:para) && el.para&.any?
          el.para.filter_map { |p| paragraph_node(p) }.each { |n| content << n }
        else
          text = extract_text(el)
          content << text_node(text) unless text.empty?
        end
        return nil if content.empty?

        Node.new(type: "annotation", attrs: attrs, content: content)
      end

      def qandaset_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        entries = Array(el.qandaentry).filter_map { |e| qandaentry_node(e) }
        return nil if entries.empty?

        Node.new(type: "qandaset", attrs: attrs, content: entries)
      end

      def qandaentry_node(el)
        attrs = { xml_id: el.xml_id }.compact
        content = []
        if el.question
          q_content = extract_content(el.question)
          content << Node.new(type: "question", attrs: {}, content: q_content) unless q_content.empty?
        end
        Array(el.answer).each do |a|
          a_content = extract_content(a)
          content << Node.new(type: "answer", attrs: {}, content: a_content) unless a_content.empty?
        end
        return nil if content.empty?

        Node.new(type: "qandaentry", attrs: attrs, content: content)
      end

      # =========================================
      # Frontmatter / Backmatter Nodes
      # =========================================

      def preface_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        fn = flush_footnotes
        content << fn if fn
        Node::Preface.new(attrs: attrs, content: content)
      end

      def titled_section_node(el, node_class)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        node_class.new(attrs: attrs, content: content)
      end

      def glossary_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        raw_entries = (el.glossentry if el.respond_to?(:glossentry)).to_a
        entries = raw_entries.filter_map { |ge| glossentry_node(ge) }
        entries = sort_glossary_entries(entries) if @sort_glossary
        Node::Glossary.new(attrs: attrs, content: entries)
      end

      def sort_glossary_entries(entries)
        entries.sort_by do |entry|
          term_node = entry.content&.find { |n| n.is_a?(Node::GlossTerm) }
          term_text = term_node&.content&.filter_map { |n| n.text if n.respond_to?(:text) }&.join&.downcase || ""
          term_text
        end
      end

      def glossentry_node(ge)
        attrs = { xml_id: ge.xml_id }.compact
        content = []

        if ge.respond_to?(:glossterm) && ge.glossterm
          term_text = ge.glossterm.content.to_s
          content << Node::GlossTerm.new(content: [text_node(term_text)])
        end

        if ge.respond_to?(:glossdef) && ge.glossdef
          def_content = extract_content(ge.glossdef)
          content << Node::GlossDef.new(content: def_content) unless def_content.empty?
        end

        if ge.respond_to?(:glosssee) && ge.glosssee
          Array(ge.glosssee).each do |gs|
            text = gs.content.to_s
            attrs_see = { otherterm: gs.otherterm }.compact
            content << Node::GlossSee.new(attrs: attrs_see, content: [text_node(text)])
          end
        end

        if ge.respond_to?(:glossseealso) && ge.glossseealso
          Array(ge.glossseealso).each do |gsa|
            text = gsa.content.to_s
            attrs_see = { otherterm: gsa.otherterm }.compact
            content << Node::GlossSeeAlso.new(attrs: attrs_see, content: [text_node(text)])
          end
        end

        return nil if content.empty?

        Node::GlossEntry.new(attrs: attrs, content: content)
      end

      def bibliography_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        entries = (el.bibliomixed if el.respond_to?(:bibliomixed)).to_a.filter_map { |bm| biblio_entry_node(bm) }
        Node::Bibliography.new(attrs: attrs, content: entries)
      end

      def biblio_entry_node(bm)
        attrs = {
          xml_id: bm.xml_id,
          role: bm.role,
        }.compact

        parts = []
        if bm.respond_to?(:abbrev) && bm.abbrev
          parts << text_node(bm.abbrev.content.to_s, marks: [Docbook::Mirror::Mark::Strong.new])
        end
        if bm.respond_to?(:citetitle) && bm.citetitle&.any?
          bm.citetitle.each { |ct| parts << citetitle_node(ct) }
        end
        if bm.respond_to?(:author) && bm.author&.any?
          authors = bm.author.filter_map { |a| a.personname&.content }.join(", ")
          parts << text_node(authors) unless authors.empty?
        end
        if bm.respond_to?(:publishername) && bm.publishername&.any?
          publishers = bm.publishername.filter_map(&:content).join(", ")
          parts << text_node(publishers) unless publishers.empty?
        end
        if bm.respond_to?(:pubdate) && bm.pubdate
          parts << text_node(bm.pubdate.to_s)
        end
        if bm.respond_to?(:link) && bm.link&.any?
          bm.link.each { |l| parts << link_node(l) }
        end
        # Fallback: raw content
        if parts.empty?
          text = extract_text(bm)
          parts << text_node(text) unless text.empty?
        end

        return nil if parts.empty?

        Node::BiblioEntry.new(attrs: attrs, content: parts)
      end

      def index_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = []

        if el.respond_to?(:indexdiv) && el.indexdiv&.any?
          el.indexdiv.each { |div| content << indexdiv_node(div) }
        end

        if el.respond_to?(:indexentry) && el.indexentry&.any?
          el.indexentry.each { |ie| content << indexentry_node(ie) }
        end

        Node::IndexBlock.new(attrs: attrs, content: content)
      end

      def indexdiv_node(div)
        attrs = {
          xml_id: div.xml_id,
          title: div.title&.content,
        }.compact
        entries = (div.indexentry if div.respond_to?(:indexentry)).to_a.filter_map { |ie| indexentry_node(ie) }
        Node::IndexDiv.new(attrs: attrs, content: entries)
      end

      def indexentry_node(ie)
        attrs = { xml_id: ie.xml_id }.compact
        content = []
        if ie.respond_to?(:primaryie) && ie.primaryie
          content << text_node(ie.primaryie.to_s)
        end
        if ie.respond_to?(:secondaryie) && ie.secondaryie
          content << text_node(ie.secondaryie.to_s)
        end
        return nil if content.empty?

        Node::IndexEntry.new(attrs: attrs, content: content)
      end

      def bibliolist_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        entries = (el.bibliomixed if el.respond_to?(:bibliomixed)).to_a.filter_map { |bm| biblio_entry_node(bm) }
        Node::Bibliography.new(attrs: attrs, content: entries)
      end

      # =========================================
      # Content Block Nodes
      # =========================================

      def equation_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        return nil if content.empty? && !el.xml_id

        # Extract image from mediaobject if present
        if content.empty? && el.respond_to?(:mediaobject) && el.mediaobject.any?
          img = figure_node(el)
          content << img if img
        end

        Node::Equation.new(attrs: attrs, content: content)
      end

      def procedure_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        steps = (el.step if el.respond_to?(:step)).to_a.filter_map { |s| step_node(s) }
        Node::Procedure.new(attrs: attrs, content: steps)
      end

      def step_node(s)
        attrs = { xml_id: s.xml_id }.compact
        content = extract_content(s)

        if s.respond_to?(:substeps) && s.substeps&.any?
          s.substeps.each do |ss|
            sub_steps = (ss.step if ss.respond_to?(:step)).to_a.filter_map { |st| step_node(st) }
            content << Node::SubSteps.new(content: sub_steps) unless sub_steps.empty?
          end
        end

        return nil if content.empty?

        Node::Step.new(attrs: attrs, content: content)
      end

      def calloutlist_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        callouts = (el.callout if el.respond_to?(:callout)).to_a.filter_map { |c| callout_node(c) }
        Node::CalloutList.new(attrs: attrs, content: callouts)
      end

      def callout_node(c)
        attrs = {
          xml_id: c.xml_id,
          arearefs: c.arearefs,
        }.compact
        content = extract_content(c)
        return nil if content.empty?

        Node::Callout.new(attrs: attrs, content: content)
      end

      def sidebar_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        return nil if content.empty?

        Node::Sidebar.new(attrs: attrs, content: content)
      end

      def address_node(el)
        attrs = { xml_id: el.xml_id }.compact
        text = extract_text(el)
        return nil if text.empty?

        Node::CodeBlock.new(
          attrs: attrs.merge({ language: "text" }),
          content: [Node::Text.new(text: text)],
        )
      end

      def legalnotice_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        return nil if content.empty?

        Node::Section.new(attrs: attrs, content: content)
      end

      # =========================================
      # Structural Nodes
      # =========================================

      def set_node(el)
        title = el.title&.content || (el.info&.title&.content if el.respond_to?(:info))
        attrs = {
          xml_id: el.xml_id,
          title: title,
        }.compact
        content = extract_content(el)
        Node::Set.new(attrs: attrs, content: content)
      end

      def topic_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        Node::Topic.new(attrs: attrs, content: content)
      end

      def sect_node(el)
        attrs = {
          xml_id: el.xml_id,
          title: el.title&.content,
        }.compact
        content = extract_content(el)
        fn = flush_footnotes
        content << fn if fn
        Node::Section.new(attrs: attrs, content: content)
      end

      # =========================================
      # Utilities
      # =========================================

      # Extract <co> callout markers from a code block element,
      # assigning sequential numbers. Returns an array of hashes.
      def extract_co_markers(el)
        markers = []
        counter = 0
        return markers unless el.respond_to?(:each_mixed_content)

        el.each_mixed_content do |node|
          next if node.is_a?(String)
          next unless node.is_a?(Docbook::Elements::Co)

          counter += 1
          id = node.xml_id if node.respond_to?(:xml_id)
          label = node.respond_to?(:label) && node.label ? node.label : counter.to_s
          markers << { number: counter, id: id, label: label }.compact
        end
        markers
      end

      # Extract text from a code block element, inserting callout marker labels.
      def extract_text_with_callouts(el, co_markers)
        return el.content.to_s unless el.respond_to?(:each_mixed_content)

        marker_idx = 0
        texts = []
        el.each_mixed_content do |node|
          if node.is_a?(String)
            texts << node
          elsif node.is_a?(Docbook::Elements::Co)
            marker = co_markers[marker_idx]
            texts << "(#{marker[:label]})"
            marker_idx += 1
          elsif node.respond_to?(:content)
            texts << node.content.to_s
          end
        end
        texts.join
      end

      def extract_text(el)
        return el.content.to_s unless el.respond_to?(:each_mixed_content)

        texts = []
        el.each_mixed_content do |node|
          if node.is_a?(String)
            texts << node
          elsif node.respond_to?(:content)
            texts << node.content.to_s
          end
        end
        texts.join
      end

      def build_xml_id_map(doc)
        map = {}
        return map unless doc.respond_to?(:each_mixed_content)

        doc.each_mixed_content do |node|
          next if node.is_a?(String)

          id = element_id(node)
          map[id] = resolve_title(node) if id && !id.empty?

          build_xml_id_map(node).each { |k, v| map[k] = v }
        end
        map
      end

      def resolve_title(node)
        title = case node
                when Docbook::Elements::RefEntry
                  resolve_refentry_title(node)
                when Docbook::Elements::Bibliomixed
                  node.abbrev&.content || node.citetitle&.first&.content
                else
                  t = node.title&.content if node.respond_to?(:title)
                  t || (node.info&.title&.content if node.respond_to?(:info))
                end
        flatten_title(title)
      end

      def flatten_title(title)
        case title
        when Array then title.map { |t| t.is_a?(String) ? t : t.to_s }.join
        when String then title
        else title.to_s
        end
      end

      # =========================================
      # Round-trip: DocbookMirror → DocBook
      # =========================================

      def to_docbook(mirror_node)
        case mirror_node.type
        when "doc"
          docbook_document(mirror_node)
        when "paragraph"
          docbook_paragraph(mirror_node)
        when "text"
          docbook_text(mirror_node)
        when "code_block"
          docbook_code_block(mirror_node)
        when "blockquote"
          docbook_blockquote(mirror_node)
        when "bullet_list"
          docbook_itemized_list(mirror_node)
        when "ordered_list"
          docbook_ordered_list(mirror_node)
        when "list_item"
          docbook_list_item(mirror_node)
        when "dl"
          docbook_variable_list(mirror_node)
        when "definition_term"
          docbook_definition_term(mirror_node)
        when "definition_description"
          docbook_definition_description(mirror_node)
        when "admonition"
          docbook_admonition(mirror_node)
        when "chapter"
          docbook_chapter(mirror_node)
        when "section"
          docbook_section(mirror_node)
        when "part"
          docbook_part(mirror_node)
        when "appendix"
          docbook_appendix(mirror_node)
        when "reference"
          docbook_reference(mirror_node)
        when "image"
          docbook_image(mirror_node)
        else
          raise Error, "Unknown node type: #{mirror_node.type}"
        end
      end

      # =========================================
      # Document
      # =========================================

      def docbook_document(mirror_node)
        attrs = mirror_node.attrs || {}
        title = attrs[:title] || attrs["title"]

        doc = Docbook::Elements::Article.new
        info = Docbook::Elements::Info.new
        if title
          title_el = Docbook::Elements::Title.new
          title_el.content = title
          info.title = title_el
        end
        doc.info = info

        if mirror_node.content
          doc.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end

        doc
      end

      # =========================================
      # Blocks
      # =========================================

      def docbook_paragraph(mirror_node)
        para = Docbook::Elements::Para.new
        process_paragraph_content(para, mirror_node)
        para
      end

      def process_paragraph_content(para, mirror_node)
        return unless mirror_node.content

        # Group content by type
        text_parts = []
        inline_elements = []

        mirror_node.content.each do |child|
          case child.type
          when "text"
            marks = child.marks || []
            if marks.empty?
              # Plain text - add to text parts
              text_parts << child.text
            else
              # Text with marks - create inline elements (don'"'"'t add to text_parts)
              marks.each do |mark|
                inline_elements << { mark: mark, text: child.text }
              end
            end
          when "soft_break"
            text_parts << "\n"
          end
        end

        # Set content as joined text
        para.content = text_parts.join

        # Process inline elements into their collections
        inline_elements.each do |item|
          mark = item[:mark]
          text = item[:text]
          el = apply_mark_to_element(text, mark)
          add_inline_to_para(para, el) if el
        end
      end

      def add_inline_to_para(para, element)
        case element
        when Docbook::Elements::Emphasis
          para.emphasis ||= []
          para.emphasis << element
        when Docbook::Elements::Literal
          para.literal ||= []
          para.literal << element
        when Docbook::Elements::Code
          para.code ||= []
          para.code << element
        when Docbook::Elements::UserInput
          para.userinput ||= []
          para.userinput << element
        when Docbook::Elements::ComputerOutput
          para.computeroutput ||= []
          para.computeroutput << element
        when Docbook::Elements::Filename
          para.filename ||= []
          para.filename << element
        when Docbook::Elements::ClassName
          para.classname ||= []
          para.classname << element
        when Docbook::Elements::Function
          para.function ||= []
          para.function << element
        when Docbook::Elements::Parameter
          para.parameter ||= []
          para.parameter << element
        when Docbook::Elements::Replaceable
          para.replaceable ||= []
          para.replaceable << element
        when Docbook::Elements::Link
          para.link ||= []
          para.link << element
        when Docbook::Elements::Xref
          para.xref ||= []
          para.xref << element
        when Docbook::Elements::Biblioref
          para.biblioref ||= []
          para.biblioref << element
        when Docbook::Elements::Tag
          para.tag ||= []
          para.tag << element
        end
      end

      def apply_mark_to_element(text, mark)
        case mark.type
        when "emphasis"
          el = Docbook::Elements::Emphasis.new
          el.content = text
          el
        when "strong"
          el = Docbook::Elements::Emphasis.new
          el.role = "bold"
          el.content = text
          el
        when "italic"
          el = Docbook::Elements::Emphasis.new
          el.role = "italic"
          el.content = text
          el
        when "code"
          role = (mark.attrs && (mark.attrs[:role] || mark.attrs["role"])) || "literal"
          el = role_to_class(role).new
          el.content = text
          el
        when "link"
          href = mark.attrs && (mark.attrs[:href] || mark.attrs["href"])
          el = Docbook::Elements::Link.new
          el.xlink_href = href
          el.content = text
          el
        when "xref"
          linkend = mark.attrs && (mark.attrs[:linkend] || mark.attrs["linkend"])
          el = Docbook::Elements::Xref.new
          el.linkend = linkend
          el.content = text
          el
        when "citation"
          bibref = mark.attrs && (mark.attrs[:bibref] || mark.attrs["bibref"])
          el = Docbook::Elements::Biblioref.new
          el.linkend = bibref
          el.content = text
          el
        when "tag"
          el = Docbook::Elements::Tag.new
          el.content = text.gsub(/^<(.+)>$/, '\1')
          el
        end
      end

      def docbook_code_block(mirror_node)
        attrs = mirror_node.attrs || {}
        language = attrs[:language] || attrs["language"]

        # Determine which code element to use
        el = if language == "text" || language.nil?
               Docbook::Elements::Screen.new
             else
               code = Docbook::Elements::Code.new
               code.language = language
               code
             end

        text = extract_text_from_content(mirror_node.content)
        el.content = text

        el
      end

      def docbook_blockquote(mirror_node)
        bq = Docbook::Elements::BlockQuote.new
        if mirror_node.content
          bq.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        bq
      end

      def docbook_itemized_list(mirror_node)
        list = Docbook::Elements::ItemizedList.new
        if mirror_node.content
          list.listitem = mirror_node.content.to_a.compact.map do |n|
            docbook_list_item(n)
          end
        end
        list
      end

      def docbook_ordered_list(mirror_node)
        list = Docbook::Elements::OrderedList.new
        if mirror_node.content
          list.listitem = mirror_node.content.to_a.compact.map do |n|
            docbook_list_item(n)
          end
        end
        list
      end

      def docbook_list_item(mirror_node)
        li = Docbook::Elements::ListItem.new
        if mirror_node.content
          li.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        li
      end

      def docbook_variable_list(mirror_node)
        vl = Docbook::Elements::VariableList.new
        if mirror_node.content
          vl.varlistentry = mirror_node.content.to_a.compact.map do |n|
            docbook_varlistentry(n)
          end
        end
        vl
      end

      def docbook_varlistentry(mirror_node)
        ve = Docbook::Elements::Varlistentry.new
        # Find term and description children
        if mirror_node.content
          term_node = mirror_node.content.to_a.find do |n|
            n.type == "definition_term"
          end
        end
        if mirror_node.content
          desc_node = mirror_node.content.to_a.find do |n|
            n.type == "definition_description"
          end
        end

        ve.term = docbook_definition_term(term_node) if term_node
        ve.definition = [docbook_definition_description(desc_node)] if desc_node

        ve
      end

      def docbook_definition_term(mirror_node)
        return nil unless mirror_node

        term = Docbook::Elements::Term.new
        term.content = process_docbook_inline(mirror_node)
        term
      end

      def docbook_definition_description(mirror_node)
        return nil unless mirror_node

        desc = Docbook::Elements::Para.new
        desc.content = process_docbook_inline(mirror_node)
        desc
      end

      ADMONITION_TYPES = {
        "note" => Docbook::Elements::Note,
        "warning" => Docbook::Elements::Warning,
        "tip" => Docbook::Elements::Tip,
        "caution" => Docbook::Elements::Caution,
        "important" => Docbook::Elements::Important,
        "danger" => Docbook::Elements::Danger,
      }.freeze

      def docbook_admonition(mirror_node)
        attrs = mirror_node.attrs || {}
        type = (attrs[:admonition_type] || attrs["admonition_type"] || "note").to_s

        adm_class = ADMONITION_TYPES[type] || Docbook::Elements::Note
        adm = adm_class.new
        if mirror_node.content
          adm.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        adm
      end

      def docbook_chapter(mirror_node)
        attrs = mirror_node.attrs || {}
        chapter = Docbook::Elements::Chapter.new
        chapter.xml_id = attrs[:xml_id] || attrs["xml_id"]
        chapter.number = attrs[:number] || attrs["number"]
        if attrs[:title] || attrs["title"]
          title = Docbook::Elements::Title.new
          title.content = attrs[:title] || attrs["title"]
          chapter.title = title
        end
        if mirror_node.content
          chapter.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        chapter
      end

      def docbook_section(mirror_node)
        attrs = mirror_node.attrs || {}
        section = Docbook::Elements::Section.new
        section.xml_id = attrs[:xml_id] || attrs["xml_id"]
        section.number = attrs[:number] || attrs["number"]
        if attrs[:title] || attrs["title"]
          title = Docbook::Elements::Title.new
          title.content = attrs[:title] || attrs["title"]
          section.title = title
        end
        if mirror_node.content
          section.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        section
      end

      def docbook_part(mirror_node)
        attrs = mirror_node.attrs || {}
        part = Docbook::Elements::Part.new
        part.number = attrs[:number] || attrs["number"]
        if attrs[:title] || attrs["title"]
          title = Docbook::Elements::Title.new
          title.content = attrs[:title] || attrs["title"]
          part.title = title
        end
        if mirror_node.content
          part.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        part
      end

      def docbook_appendix(mirror_node)
        attrs = mirror_node.attrs || {}
        appendix = Docbook::Elements::Appendix.new
        appendix.xml_id = attrs[:xml_id] || attrs["xml_id"]
        appendix.number = attrs[:number] || attrs["number"]
        if attrs[:title] || attrs["title"]
          title = Docbook::Elements::Title.new
          title.content = attrs[:title] || attrs["title"]
          appendix.title = title
        end
        if mirror_node.content
          appendix.para = mirror_node.content.to_a.compact.map do |n|
            to_docbook(n)
          end
        end
        appendix
      end

      def docbook_reference(mirror_node)
        attrs = mirror_node.attrs || {}
        ref = Docbook::Elements::RefEntry.new
        ref.xml_id = attrs[:xml_id] || attrs["xml_id"]
        if attrs[:title] || attrs["title"]
          refmeta = Docbook::Elements::RefMeta.new
          refmeta.refentrytitle = attrs[:title] || attrs["title"]
          ref.refmeta = refmeta
        end
        ref
      end

      def docbook_image(mirror_node)
        attrs = mirror_node.attrs || {}
        figure = Docbook::Elements::Figure.new
        figure.xml_id = attrs[:xml_id] || attrs["xml_id"]
        if attrs[:title] || attrs["title"]
          title = Docbook::Elements::Title.new
          title.content = attrs[:title] || attrs["title"]
          figure.title = title
        end
        imageobject = Docbook::Elements::ImageObject.new
        imagedata = Docbook::Elements::ImageData.new
        imagedata.fileref = attrs[:src] || attrs["src"]
        imageobject.imagedata = imagedata
        figure.imageobject = [imageobject]
        figure
      end

      # =========================================
      # Inline Content
      # =========================================

      def process_docbook_inline(mirror_node)
        inline_content = []

        return inline_content unless mirror_node.content

        mirror_node.content.each do |child|
          case child.type
          when "text"
            inline_content << docbook_text(child)
          when "soft_break"
            inline_content << "\n"
          end
        end

        inline_content
      end

      def docbook_text(mirror_node)
        text = mirror_node.text || ""
        marks = mirror_node.marks || []

        # Process marks in order
        marks.each do |mark|
          text = apply_mark_to_text(text, mark)
        end

        text
      end

      def apply_mark_to_text(text, mark)
        case mark.type
        when "emphasis"
          wrap_in_element(text, Docbook::Elements::Emphasis)
        when "strong"
          el = Docbook::Elements::Emphasis.new
          el.role = "bold"
          el.content = text
          el
        when "italic"
          el = Docbook::Elements::Emphasis.new
          el.role = "italic"
          el.content = text
          el
        when "code"
          role = (mark.attrs && (mark.attrs[:role] || mark.attrs["role"])) || "literal"
          wrap_in_element(text, role_to_class(role))
        when "link"
          href = mark.attrs && (mark.attrs[:href] || mark.attrs["href"])
          wrap_in_link(text, href)
        when "xref"
          linkend = mark.attrs && (mark.attrs[:linkend] || mark.attrs["linkend"])
          wrap_in_xref(text, linkend)
        when "citation"
          bibref = mark.attrs && (mark.attrs[:bibref] || mark.attrs["bibref"])
          wrap_in_biblioref(text, bibref)
        when "tag"
          tag = Docbook::Elements::Tag.new
          tag.content = text.gsub(/^<(.+)>$/, '\1')
          tag
        else
          text
        end
      end

      def wrap_in_element(text, klass)
        el = klass.new
        el.content = text
        el
      end

      def role_to_class(role)
        case role.to_s
        when "literal" then Docbook::Elements::Literal
        when "code" then Docbook::Elements::Code
        when "userinput" then Docbook::Elements::UserInput
        when "computeroutput" then Docbook::Elements::ComputerOutput
        when "filename" then Docbook::Elements::Filename
        when "classname" then Docbook::Elements::ClassName
        when "function" then Docbook::Elements::Function
        when "parameter" then Docbook::Elements::Parameter
        when "replaceable" then Docbook::Elements::Replaceable
        else Docbook::Elements::Literal
        end
      end

      def wrap_in_link(text, href)
        link = Docbook::Elements::Link.new
        link.xlink_href = href
        link.content = text
        link
      end

      def wrap_in_xref(text, linkend)
        xref = Docbook::Elements::Xref.new
        xref.linkend = linkend
        xref.content = text
        xref
      end

      def wrap_in_biblioref(text, bibref)
        biblioref = Docbook::Elements::Biblioref.new
        biblioref.linkend = bibref
        biblioref.content = text
        biblioref
      end

      # =========================================
      # Utilities
      # =========================================

      def extract_text_from_content(content)
        return "" unless content

        content.map do |node|
          if node.respond_to?(:text) && node.text
            node.text
          elsif node.respond_to?(:content)
            extract_text_from_content(node.content)
          end
        end.join
      end

      # Make to_docbook public
      public :to_docbook
    end
  end
end
