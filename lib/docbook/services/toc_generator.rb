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
        root_elements.filter_map { |element| build_toc_node(element) }
      end

      private

      def get_root_elements
        case @document
        when Elements::Book
          roots = []
          # Frontmatter first
          roots.concat(Array(@document.dedication)) if @document.respond_to?(:dedication)
          roots.concat(Array(@document.acknowledgements)) if @document.respond_to?(:acknowledgements)
          roots.concat(Array(@document.preface)) if @document.respond_to?(:preface)
          # Body
          roots.concat(Array(@document.part)) if @document.respond_to?(:part)
          roots.concat(Array(@document.chapter)) if @document.respond_to?(:chapter)
          # Backmatter
          roots.concat(Array(@document.appendix)) if @document.respond_to?(:appendix)
          roots.concat(Array(@document.reference)) if @document.respond_to?(:reference)
          roots.concat(Array(@document.glossary)) if @document.respond_to?(:glossary)
          roots.concat(Array(@document.bibliography)) if @document.respond_to?(:bibliography)
          roots.concat(Array(@document.index)) if @document.respond_to?(:index)
          roots.concat(Array(@document.colophon)) if @document.respond_to?(:colophon)
          roots
        when Elements::Set
          Array(@document.book)
        when Elements::Article
          roots = []
          roots.concat(Array(@document.section))
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
          number: nil, # Numbering added separately
        )

        # Recursively add children
        children = get_child_sections(element)
        if children.any?
          node.children = children.filter_map do |child|
            build_toc_node(child)
          end
        end

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
             Elements::Preface, Elements::Part, Elements::Section,
             Elements::Dedication, Elements::Acknowledgements, Elements::Colophon,
             Elements::Glossary, Elements::Bibliography, Elements::Index, Elements::SetIndex,
             Elements::Set, Elements::Topic,
             Elements::Sect1, Elements::Sect2, Elements::Sect3, Elements::Sect4, Elements::Sect5,
             Elements::RefSection, Elements::RefSect1, Elements::RefSect2, Elements::RefSect3
          info_title = element.info&.title&.content if element.respond_to?(:info)
          info_title || element.title&.content || "Untitled"
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
          children.concat(Array(element.dedication)) if element.respond_to?(:dedication)
          children.concat(Array(element.acknowledgements)) if element.respond_to?(:acknowledgements)
          children.concat(Array(element.preface)) if element.respond_to?(:preface)
          children.concat(Array(element.part)) if element.respond_to?(:part)
          children.concat(Array(element.chapter)) if element.respond_to?(:chapter)
          children.concat(Array(element.appendix)) if element.respond_to?(:appendix)
          children.concat(Array(element.reference)) if element.respond_to?(:reference)
          children.concat(Array(element.glossary)) if element.respond_to?(:glossary)
          children.concat(Array(element.bibliography)) if element.respond_to?(:bibliography)
          children.concat(Array(element.index)) if element.respond_to?(:index)
          children.concat(Array(element.colophon)) if element.respond_to?(:colophon)
        when Elements::Set
          children.concat(Array(element.book))
        when Elements::Article
          children.concat(Array(element.section))
        when Elements::Part
          children.concat(Array(element.chapter))
          children.concat(Array(element.reference))
          children.concat(Array(element.appendix))
        when Elements::Chapter, Elements::Appendix, Elements::Preface
          children.concat(Array(element.section))
          children.concat(sect_children(element))
        when Elements::Section
          children.concat(Array(element.section))
        when Elements::Reference
          children.concat(Array(element.refentry))
        when Elements::RefEntry
          children.concat(Array(element.refsect1)) if element.respond_to?(:refsect1)
          children.concat(Array(element.refsect2)) if element.respond_to?(:refsect2)
          children.concat(Array(element.refsect3)) if element.respond_to?(:refsect3)
          children.concat(Array(element.refsection)) if element.respond_to?(:refsection)
        when Elements::Glossary
          # Glossary entries are typically not shown in TOC
        when Elements::Bibliography
          # Bibliography entries are typically not shown in TOC
        when Elements::Index, Elements::SetIndex
        # Index entries are not shown in TOC
        # sect1-5: each sectN has sectN+1 children
        when Elements::Sect1
          children.concat(sect1_children(element))
        when Elements::Sect2
          children.concat(Array(element.sect3))
        when Elements::Sect3
          children.concat(Array(element.sect4))
        when Elements::Sect4
          children.concat(Array(element.sect5))
        end

        children.select { |e| section_like?(e) }
      end

      def sect1_children(element)
        result = []
        result.concat(Array(element.section))
        result.concat(Array(element.sect2))
        result
      end

      def sect_children(element)
        result = []
        result.concat(Array(element.sect1)) if element.respond_to?(:sect1)
        result
      end

      def section_like?(element)
        element.is_a?(Elements::Section) ||
          element.is_a?(Elements::Chapter) ||
          element.is_a?(Elements::Appendix) ||
          element.is_a?(Elements::Part) ||
          element.is_a?(Elements::Reference) ||
          element.is_a?(Elements::RefEntry) ||
          element.is_a?(Elements::Preface) ||
          element.is_a?(Elements::Dedication) ||
          element.is_a?(Elements::Acknowledgements) ||
          element.is_a?(Elements::Colophon) ||
          element.is_a?(Elements::Glossary) ||
          element.is_a?(Elements::Bibliography) ||
          element.is_a?(Elements::Index) ||
          element.is_a?(Elements::SetIndex) ||
          element.is_a?(Elements::Set) ||
          element.is_a?(Elements::Topic) ||
          element.is_a?(Elements::Sect1) ||
          element.is_a?(Elements::Sect2) ||
          element.is_a?(Elements::Sect3) ||
          element.is_a?(Elements::Sect4) ||
          element.is_a?(Elements::Sect5) ||
          element.is_a?(Elements::RefSection) ||
          element.is_a?(Elements::RefSect1) ||
          element.is_a?(Elements::RefSect2) ||
          element.is_a?(Elements::RefSect3)
      end
    end
  end
end
