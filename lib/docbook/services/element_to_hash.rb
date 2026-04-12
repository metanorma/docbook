# frozen_string_literal: true

module Docbook
  module Services
    # Converts Lutaml elements to Vue-friendly hashes
    # Uses Lutaml's as_json but ensures compatibility with Vue rendering
    class ElementToHash
      def initialize(element)
        @element = element
      end

      # Convert element to hash suitable for Vue
      def to_h
        case @element
        when Elements::RefEntry
          refentry_to_h
        when Elements::Para
          para_to_h
        when Elements::VariableList
          variablelist_to_h
        when Elements::OrderedList
          orderedlist_to_h
        when Elements::ItemizedList
          itemizedlist_to_h
        when Elements::ProgramListing, Elements::Screen
          codelike_to_h
        when Elements::Example, Elements::InformalExample
          example_to_h
        when Elements::Figure, Elements::InformalFigure
          figure_to_h
        when Elements::Table
          table_to_h
        when Elements::Note, Elements::Warning, Elements::Caution,
             Elements::Important, Elements::Tip, Elements::Danger
          admonition_to_h
        when Elements::BlockQuote
          blockquote_to_h
        when Elements::Title
          { type: "title", text: @element.content }
        else
          generic_to_h
        end
      end

      private

      def refentry_to_h
        content = @element.as_json

        # Flatten for Vue - extract key fields
        result = {
          type: "refentry",
          id: @element.xml_id
        }

        # Extract refmeta info
        if @element.refmeta
          result[:refentrytitle] = @element.refmeta.refentrytitle&.content
          result[:refmiscinfo] = @element.refmeta.refmiscinfo&.map(&:content)
        end

        # Extract refnamediv info
        if @element.refnamediv
          result[:refname] = @element.refnamediv.refname&.map(&:content)&.join(" ")
          result[:refpurpose] = @element.refnamediv.refpurpose&.content
          result[:refclass] = @element.refnamediv.refclass&.content
        end

        # Convert refsection content
        if @element.refsection&.any?
          result[:sections] = @element.refsection.map do |rs|
            section_content_to_h(rs)
          end
        end

        result
      end

      def section_content_to_h(section)
        children = []

        # Process all child elements
        if section.respond_to?(:elements)
          section.elements.each do |el|
            children << ElementToHash.new(el).to_h
          end
        end

        { type: "section", children: children }
      end

      def para_to_h
        content = extract_inline_content(@element)
        {
          type: "para",
          content: content
        }
      end

      def variablelist_to_h
        {
          type: "variablelist",
          items: @element.varlistentry.map do |ve|
            terms = ve.term&.map { |t| extract_inline_content(t) } || []
            definition = if ve.listitem&.respond_to?(:para)
              ve.listitem.para.map { |p| extract_inline_content(p) }
            elsif ve.listitem&.respond_to?(:elements)
              ve.listitem.elements.map { |e| ElementToHash.new(e).to_h }
            else
              []
            end
            { terms: terms, definition: definition }
          end
        }
      end

      def orderedlist_to_h
        {
          type: "orderedlist",
          items: @element.listitem.map do |li|
            items = []
            if li.respond_to?(:para)
              items = li.para.map { |p| extract_inline_content(p) }
            elsif li.respond_to?(:elements)
              items = li.elements.map { |e| ElementToHash.new(e).to_h }
            end
            items
          end
        }
      end

      def itemizedlist_to_h
        {
          type: "itemizedlist",
          items: @element.listitem.map do |li|
            items = []
            if li.respond_to?(:para)
              items = li.para.map { |p| extract_inline_content(p) }
            elsif li.respond_to?(:elements)
              items = li.elements.map { |e| ElementToHash.new(e).to_h }
            end
            items
          end
        }
      end

      def codelike_to_h
        code_text = build_code_text
        {
          type: "code",
          text: code_text,
          language: @element.language
        }
      end

      def example_to_h
        {
          type: "example",
          content: @element.elements.map { |e| ElementToHash.new(e).to_h }
        }
      end

      def figure_to_h
        result = {
          type: "figure",
          id: @element.xml_id
        }

        if @element.respond_to?(:mediaobject) && @element.mediaobject
          obj = @element.mediaobject
          if obj.respond_to?(:imageobject) && obj.imageobject&.first
            imagedata = obj.imageobject.first.imagedata
            result[:src] = imagedata&.fileref
            result[:alt] = obj.imageobject.first.textobject&.phrase&.content
          end
        end

        result
      end

      def table_to_h
        # Simplified table representation
        {
          type: "table",
          id: @element.xml_id,
          rows: []  # Would need complex traversal
        }
      end

      def admonition_to_h
        title = @element.respond_to?(:title) ? @element.title&.content : nil
        content = @element.elements.map { |e| ElementToHash.new(e).to_h } if @element.elements

        {
          type: @element.class.name.split('::').last.downcase,
          title: title,
          content: content
        }
      end

      def blockquote_to_h
        attribution = @element.attribution&.content if @element.attribution
        content = @element.elements.map { |e| ElementToHash.new(e).to_h } if @element.elements

        {
          type: "blockquote",
          attribution: attribution,
          content: content
        }
      end

      def generic_to_h
        # Default: try to use as_json
        if @element.respond_to?(:as_json)
          @element.as_json.merge(type: @element.class.name.split('::').last.downcase)
        else
          { type: "unknown", content: @element.to_s }
        end
      end

      def extract_inline_content(element)
        return [] unless element

        content = []
        if element.respond_to?(:content)
          c = element.content
          if c.is_a?(Array)
            c.each { |item| content << process_inline_item(item) }
          elsif c.is_a?(String)
            content << { type: "text", value: c }
          end
        elsif element.respond_to?(:elements)
          element.elements.each do |el|
            content << process_inline_item(el)
          end
        end
        content
      end

      def process_inline_item(item)
        case item
        when String
          { type: "text", value: item }
        when Elements::Emphasis
          {
            type: "emphasis",
            role: item.role,
            content: extract_inline_content(item)
          }
        when Elements::Link
          {
            type: "link",
            href: item.href,
            content: extract_inline_content(item)
          }
        when Elements::Xref
          {
            type: "xref",
            linkend: item.linkend,
            content: item.content || item.linkend
          }
        when Elements::Literal, Elements::Code
          { type: "codetext", value: item.content }
        when Elements::Tag
          { type: "tag", value: "<#{item.content}>" }
        when Elements::Quote
          { type: "quote", value: item.content }
        else
          if item.respond_to?(:content)
            { type: "text", value: item.content.to_s }
          else
            { type: "text", value: item.to_s }
          end
        end
      end

      def build_code_text
        if @element.respond_to?(:content)
          c = @element.content
          c.is_a?(Array) ? c.join : c.to_s
        else
          ""
        end
      end
    end
  end
end
