# frozen_string_literal: true

module Docbook
  module Mirror
    class Node
      PM_TYPE = "node"

      attr_accessor :type, :attrs, :content, :marks

      def initialize(type: nil, attrs: {}, content: [], marks: [])
        @type = type || self.class::PM_TYPE
        @attrs = attrs || {}
        @content = content || []
        @marks = marks || []
      end

      def to_h
        result = { "type" => type }
        result["attrs"] = attrs.transform_keys(&:to_s) if attrs && !attrs.empty?
        if marks && !marks.empty?
          result["marks"] = marks.map { |m| m.respond_to?(:to_h) ? m.to_h : m }
        end
        if content && !content.empty?
          result["content"] = content.map do |i|
            i.respond_to?(:to_h) ? i.to_h : i
          end
        end
        result
      end

      alias to_hash to_h

      def to_json(**options)
        to_h.to_json(options)
      end

      def self.from_h(hash)
        return nil unless hash

        type = hash["type"]
        attrs = hash["attrs"] || {}
        content = hash["content"] || []
        marks = hash["marks"] || []
        klass = NODES[type] || Node

        # Use class-specific from_h if available
        if klass.respond_to?(:from_h) && klass != Node
          klass.from_h(hash)
        else
          klass.new(
            attrs: attrs.transform_keys(&:to_sym),
            content: content.map { |c| Node.from_h(c) },
            marks: marks.map { |m| Docbook::Mirror::Mark.from_h(m) },
          )
        end
      end

      def text_content
        return "" unless content

        content.map do |item|
          if item.is_a?(Node)
            item.text_content
          else
            (item.is_a?(String) ? item : "")
          end
        end.join
      end

      NODES = Hash.new

      # Nested classes for all node types
      class Text < Node
        PM_TYPE = "text"
        attr_accessor :text

        def initialize(text: "", **)
          super(**)
          @text = text
        end

        def to_h
          result = super
          result["text"] = text.to_s
          result
        end

        def text_content
          text.to_s
        end

        def self.from_h(hash)
          return nil unless hash

          new(
            text: hash["text"] || "",
            attrs: (hash["attrs"] || {}).transform_keys(&:to_sym),
            marks: (hash["marks"] || []).map do |m|
              Docbook::Mirror::Mark.from_h(m)
            end,
          )
        end
      end

      class Paragraph < Node
        PM_TYPE = "paragraph"
      end

      class Document < Node
        PM_TYPE = "doc"
      end

      class Heading < Node
        PM_TYPE = "heading"
      end

      class CodeBlock < Node
        PM_TYPE = "code_block"
      end

      class Blockquote < Node
        PM_TYPE = "blockquote"
      end

      class BulletList < Node
        PM_TYPE = "bullet_list"
      end

      class OrderedList < Node
        PM_TYPE = "ordered_list"
      end

      class ListItem < Node
        PM_TYPE = "list_item"
      end

      class DefinitionList < Node
        PM_TYPE = "dl"
      end

      class DefinitionTerm < Node
        PM_TYPE = "definition_term"
      end

      class DefinitionDescription < Node
        PM_TYPE = "definition_description"
      end

      class Image < Node
        PM_TYPE = "image"
      end

      class Admonition < Node
        PM_TYPE = "admonition"
      end

      class Chapter < Node
        PM_TYPE = "chapter"
      end

      class Appendix < Node
        PM_TYPE = "appendix"
      end

      class Part < Node
        PM_TYPE = "part"
      end

      class Reference < Node
        PM_TYPE = "reference"
      end

      class RefEntry < Node
        PM_TYPE = "refentry"
      end

      class RefSection < Node
        PM_TYPE = "refsection"
      end

      class Section < Node
        PM_TYPE = "section"
      end

      class Table < Node
        PM_TYPE = "table"
      end

      class TableHead < Node
        PM_TYPE = "table_head"
      end

      class TableBody < Node
        PM_TYPE = "table_body"
      end

      class TableRow < Node
        PM_TYPE = "table_row"
      end

      class TableCell < Node
        PM_TYPE = "table_cell"
      end

      # Register node types
      NODES["text"] = Text
      NODES["paragraph"] = Paragraph
      NODES["doc"] = Document
      NODES["heading"] = Heading
      NODES["code_block"] = CodeBlock
      NODES["blockquote"] = Blockquote
      NODES["bullet_list"] = BulletList
      NODES["ordered_list"] = OrderedList
      NODES["list_item"] = ListItem
      NODES["dl"] = DefinitionList
      NODES["definition_term"] = DefinitionTerm
      NODES["definition_description"] = DefinitionDescription
      NODES["image"] = Image
      NODES["admonition"] = Admonition
      NODES["chapter"] = Chapter
      NODES["appendix"] = Appendix
      NODES["part"] = Part
      NODES["reference"] = Reference
      NODES["refentry"] = RefEntry
      NODES["refsection"] = RefSection
      NODES["section"] = Section
      NODES["table"] = Table
      NODES["table_head"] = TableHead
      NODES["table_body"] = TableBody
      NODES["table_row"] = TableRow
      NODES["table_cell"] = TableCell
    end
  end
end
