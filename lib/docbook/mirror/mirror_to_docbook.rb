# frozen_string_literal: true

module Docbook
  module Mirror
    # Transforms DocbookMirror node tree back into DocBook element tree.
    #
    # This is the reverse direction of the transformation: ProseMirror-style
    # JSON nodes are converted back into DocBook XML element objects, enabling
    # round-trip fidelity (DocBook -> Mirror -> DocBook).
    #
    # Usage:
    #   mirror_doc = DocbookToMirror.new.call(doc)
    #   docbook_el = MirrorToDocbook.new.call(mirror_doc)
    #
    class MirrorToDocbook
      ADMONITION_TYPES = {
        "note" => Docbook::Elements::Note,
        "warning" => Docbook::Elements::Warning,
        "tip" => Docbook::Elements::Tip,
        "caution" => Docbook::Elements::Caution,
        "important" => Docbook::Elements::Important,
        "danger" => Docbook::Elements::Danger,
      }.freeze

      # Entry point: Convert DocbookMirror node to DocBook element
      def call(mirror_node)
        to_docbook(mirror_node)
      end

      # =========================================
      # Node dispatch
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
          title_el.content = [title]
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
              # Text with marks - create inline elements (don't add to text_parts)
              marks.each do |mark|
                inline_elements << { mark: mark, text: child.text }
              end
            end
          when "soft_break"
            text_parts << "\n"
          end
        end

        # Set content as joined text
        para.content = [text_parts.join]

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
          el.content = [text]
          el
        when "strong"
          el = Docbook::Elements::Emphasis.new
          el.role = "bold"
          el.content = [text]
          el
        when "italic"
          el = Docbook::Elements::Emphasis.new
          el.role = "italic"
          el.content = [text]
          el
        when "code"
          role = (mark.attrs && (mark.attrs[:role] || mark.attrs["role"])) || "literal"
          el = role_to_class(role).new
          el.content = [text]
          el
        when "link"
          href = mark.attrs && (mark.attrs[:href] || mark.attrs["href"])
          el = Docbook::Elements::Link.new
          el.xlink_href = href
          el.content = [text]
          el
        when "xref"
          linkend = mark.attrs && (mark.attrs[:linkend] || mark.attrs["linkend"])
          el = Docbook::Elements::Xref.new
          el.linkend = linkend
          el.content = [text]
          el
        when "citation"
          bibref = mark.attrs && (mark.attrs[:bibref] || mark.attrs["bibref"])
          el = Docbook::Elements::Biblioref.new
          el.linkend = bibref
          el.content = [text]
          el
        when "tag"
          el = Docbook::Elements::Tag.new
          el.content = [text.gsub(/^<(.+)>$/, '\1')]
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
        el.content = [text]

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
          title.content = [attrs[:title] || attrs["title"]]
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
          title.content = [attrs[:title] || attrs["title"]]
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
          title.content = [attrs[:title] || attrs["title"]]
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
          title.content = [attrs[:title] || attrs["title"]]
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
          title.content = [attrs[:title] || attrs["title"]]
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
          el.content = [text]
          el
        when "italic"
          el = Docbook::Elements::Emphasis.new
          el.role = "italic"
          el.content = [text]
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
          tag.content = [text.gsub(/^<(.+)>$/, '\1')]
          tag
        else
          text
        end
      end

      def wrap_in_element(text, klass)
        el = klass.new
        el.content = [text]
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
        else
          begin
            Docbook::Elements.const_get(role.to_s.split("_").map(&:capitalize).join)
          rescue StandardError
            Docbook::Elements::Literal
          end
        end
      end

      def wrap_in_link(text, href)
        link = Docbook::Elements::Link.new
        link.xlink_href = href
        link.content = [text]
        link
      end

      def wrap_in_xref(text, linkend)
        xref = Docbook::Elements::Xref.new
        xref.linkend = linkend
        xref.content = [text]
        xref
      end

      def wrap_in_biblioref(text, bibref)
        biblioref = Docbook::Elements::Biblioref.new
        biblioref.linkend = bibref
        biblioref.content = [text]
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
    end
  end
end
