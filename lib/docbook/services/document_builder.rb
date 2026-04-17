# frozen_string_literal: true

module Docbook
  module Services
    # Builds the complete DocumentRoot from a parsed Docbook document
    class DocumentBuilder
      def initialize(document, options = {})
        @document = document
        @options = options
      end

      def build
        Models::DocumentRoot.new(
          title: extract_title,
          metadata: build_metadata,
          toc: generate_toc,
          sections: build_sections,
          index: generate_index,
          numbering: generate_numbering,
          generator: "docbook-gem/#{Docbook::VERSION}",
          generated_at: Time.now.utc.iso8601,
        )
      end

      private

      def extract_title
        (@document.respond_to?(:title) && @document.title&.content) ||
          (@document.respond_to?(:info) && @document.info&.title&.content) ||
          "Untitled Document"
      end

      def build_metadata
        metadata = Models::DocumentMetadata.new

        if @document.respond_to?(:info)
          info = @document.info
          metadata.author = extract_author(info)
          metadata.title = info.title&.content if info.respond_to?(:title)
          metadata.subtitle = info.subtitle&.content if info.respond_to?(:subtitle)
          metadata.productname = info.productname&.content if info.respond_to?(:productname)
          if info.respond_to?(:date) || info.respond_to?(:pubdate)
            metadata.pubdate = info.date&.content || info.pubdate&.content
          end
        end

        metadata
      end

      def extract_author(info)
        return nil unless info.respond_to?(:author)

        author = info.author
        return nil unless author

        if author.respond_to?(:personname)
          author.personname&.content ||
            [author.personname&.firstname&.content,
             author.personname&.surname&.content].compact.join(" ")
        elsif author.respond_to?(:orgname)
          author.orgname&.content
        else
          author.content
        end
      end

      def generate_toc
        TocGenerator.new(@document).generate
      end

      def generate_index
        IndexGenerator.new(@document).generate
      end

      def generate_numbering
        NumberingService.new(@document).generate
      end

      def build_sections
        sections = []

        root_elements = case @document
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

        root_elements.each do |element|
          section = build_section(element)
          sections << section if section
        end

        sections
      end

      def build_section(element)
        type = element_type(element)
        return nil unless type

        section = Models::SectionRoot.new(
          id: element.xml_id || generate_id(element),
          type: type,
          title: extract_element_title(element),
          number: get_section_number(element),
        )

        # Convert content to hash
        section.content = build_section_content(element)

        # Process children
        children = build_child_sections(element)
        section.children = children if children.any?

        # For refentry, extract refname
        if element.is_a?(Elements::RefEntry)
          section.refname = element.refnamediv&.refname&.map(&:content)&.join(" ") ||
            element.refmeta&.refentrytitle&.content
        end

        section
      end

      def element_type(element)
        case element
        when Elements::Part then "part"
        when Elements::Chapter then "chapter"
        when Elements::Appendix then "appendix"
        when Elements::Section then "section"
        when Elements::Reference then "reference"
        when Elements::RefEntry then "refentry"
        when Elements::Preface then "preface"
        when Elements::Article then "article"
        when Elements::Book then "book"
        end
      end

      def extract_element_title(element)
        case element
        when Elements::RefEntry
          element.refnamediv&.refname&.map(&:content)&.join(" ") ||
            element.refmeta&.refentrytitle&.content ||
            "Untitled"
        when Elements::Reference
          element.info&.title&.content || element.title&.content || "Reference"
        else
          element.info&.title&.content ||
            element.title&.content ||
            "Untitled"
        end
      end

      def generate_id(element)
        "section-#{element.class.name.split("::").last.downcase}-#{element.object_id}"
      end

      def get_section_number(_element)
        # Will be filled in by numbering service
        nil
      end

      def build_section_content(element)
        # Use ElementToHash to convert child elements
        blocks = []

        if element.respond_to?(:elements)
          element.elements.each do |child|
            next if skip_element?(child)

            block = ElementToHash.new(child).to_h
            blocks << block if block
          end
        end

        # For refentry, also process refsection
        if element.is_a?(Elements::RefEntry)
          element.refsection&.each do |rs|
            rs.elements&.each do |child|
              next if skip_element?(child)

              block = ElementToHash.new(child).to_h
              blocks << block if block
            end
          end
        end

        blocks
      end

      def skip_element?(element)
        element.is_a?(Elements::Title) ||
          element.is_a?(Elements::Info) ||
          element.is_a?(Elements::IndexTerm) ||
          (element.is_a?(Elements::Simplesect) && element.title.nil?)
      end

      def build_child_sections(element)
        children = []

        child_elements = get_child_elements(element)

        child_elements.each do |child|
          next unless section_like?(child)

          section = build_section(child)
          children << section if section
        end

        children
      end

      def get_child_elements(element)
        case element
        when Elements::Book
          children = []
          children.concat(Array(element.part))
          children.concat(Array(element.chapter))
          children.concat(Array(element.appendix))
          children.concat(Array(element.preface))
          children
        when Elements::Article
          children = []
          children.concat(Array(element.section))
          children.concat(Array(element.article))
          children
        when Elements::Part
          children = []
          children.concat(Array(element.chapter))
          children.concat(Array(element.appendix))
          children
        when Elements::Chapter, Elements::Appendix, Elements::Preface
          Array(element.section)
        when Elements::Section
          Array(element.section)
        when Elements::Reference
          Array(element.refentry)
        else
          []
        end
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
