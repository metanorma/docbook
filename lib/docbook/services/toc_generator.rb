# frozen_string_literal: true

module Docbook
  module Services
    # Generates hierarchical TOC from document sections
    class TocGenerator
      include ElementIdHelper

      def initialize(document)
        @document = document
      end

      def generate
        root_elements = get_root_elements
        root_elements.map { |element| build_toc_node(element) }.compact
      end

      private

      def get_root_elements
        case @document
        when Elements::Book
          roots = []
          roots.concat(Array(@document.part))
          roots.concat(Array(@document.chapter))
          roots.concat(Array(@document.appendix))
          roots.concat(Array(@document.preface))
          roots
        when Elements::Article
          roots = []
          roots.concat(Array(@document.section))
          roots.concat(Array(@document.article))
          roots
        else
          Array(@document.elements)
        end
      end

      def build_toc_node(element)
        return nil unless can_have_title?(element)

        node = Models::TocNode.new(
          id: get_id(element),
          title: get_title(element),
          type: element_type(element),
          number: nil # Numbering added separately
        )

        # Recursively add children
        children = get_child_sections(element)
        node.children = children.map { |child| build_toc_node(child) }.compact if children.any?

        node
      end

      def can_have_title?(element)
        element.respond_to?(:title) ||
          element.respond_to?(:info) ||
          element.respond_to?(:refnamediv)
      end

      def get_title(element)
        case element
        when Elements::RefEntry
          resolve_refentry_title(element) || "Untitled"
        when Elements::Reference
          element.info&.title&.content ||
            element.title&.content ||
            "Reference"
        when Elements::Book, Elements::Article, Elements::Chapter, Elements::Appendix,
             Elements::Preface, Elements::Part, Elements::Section
          element.info&.title&.content ||
            element.title&.content ||
            "Untitled"
        else
          "Untitled"
        end
      end

      def get_id(element)
        element_id(element)
      end

      def element_type(element)
        element.class.name.split("::").last.downcase
      end

      def get_child_sections(element)
        children = []

        case element
        when Elements::Book
          # Book has specific child element collections
          children.concat(Array(element.part))
          children.concat(Array(element.chapter))
          children.concat(Array(element.appendix))
          children.concat(Array(element.preface))
        when Elements::Article
          children.concat(Array(element.section))
          children.concat(Array(element.article))
        when Elements::Part
          children.concat(Array(element.chapter))
          children.concat(Array(element.reference))
          children.concat(Array(element.appendix))
        when Elements::Chapter, Elements::Appendix, Elements::Preface
          children.concat(Array(element.section))
        when Elements::Section
          children.concat(Array(element.section))
        when Elements::Reference
          children.concat(Array(element.refentry))
        end

        children.select { |e| section_like?(e) }
      end

      def section_like?(element)
        element.is_a?(Elements::Section) ||
          element.is_a?(Elements::Chapter) ||
          element.is_a?(Elements::Appendix) ||
          element.is_a?(Elements::Part) ||
          element.is_a?(Elements::Reference) ||
          element.is_a?(Elements::RefEntry) ||
          element.is_a?(Elements::Preface)
      end
    end
  end
end
