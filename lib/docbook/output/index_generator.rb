# frozen_string_literal: true

module Docbook
  module Output
    # Collects all indexterms from a document for index generation
    class IndexCollector
      def initialize(document)
        @document = document
        @index_terms = []
      end

      # Collect all indexterms from the document
      def collect
        @index_terms = []
        traverse_element(@document)
        @index_terms
      end

      # Get indexterms grouped by type
      def by_type
        result = {}
        @index_terms.each do |term|
          type = term[:type] || "default"
          result[type] ||= []
          result[type] << term
        end
        result
      end

      private

      def traverse_element(element, section_info = {})
        return unless element

        # Collect section info for linking based on element type
        section_info = update_section_info(element, section_info)

        # Check for indexterm on this element
        each_attr(element, :indexterm) do |it|
          process_indexterm(it, section_info)
        end

        # Traverse children based on element type
        case element
        when Elements::Book
          traverse_book(element, section_info)
        when Elements::Part
          traverse_part(element, section_info)
        when Elements::Article
          traverse_article(element, section_info)
        when Elements::Chapter
          traverse_chapter(element, section_info)
        when Elements::Appendix
          traverse_appendix(element, section_info)
        when Elements::Section
          traverse_section(element, section_info)
        when Elements::Simplesect
          traverse_simplesect(element, section_info)
        when Elements::RefEntry
          traverse_refentry(element, section_info)
        when Elements::RefSection
          traverse_refsection(element, section_info)
        when Elements::Para
          # Para children are handled via mixed content traversal
          traverse_mixed_content(element, section_info)
        when Elements::ListItem
          traverse_listitem(element, section_info)
        when Elements::Entry
          traverse_entry(element, section_info)
        end
      end

      def update_section_info(element, current_info)
        info = current_info.dup
        if element.xml_id
          info[:id] = element.xml_id
          info[:title] = element_title(element)
        elsif element.respond_to?(:title) && element.title
          info[:title] = element.title.content.to_s
        end
        info
      end

      def traverse_book(book, section_info)
        each_attr(book, :part) { |p| traverse_element(p, section_info) }
        each_attr(book, :chapter) { |c| traverse_element(c, section_info) }
        each_attr(book, :appendix) { |a| traverse_element(a, section_info) }
        each_attr(book, :preface) { |p| traverse_element(p, section_info) }
        each_attr(book, :glossary) { |g| traverse_element(g, section_info) }
        each_attr(book, :bibliography) { |b| traverse_element(b, section_info) }
        each_attr(book, :index) { |i| traverse_element(i, section_info) }
        each_attr(book, :setindex) { |si| traverse_element(si, section_info) }
      end

      def traverse_part(part, section_info)
        each_attr(part, :part) { |p| traverse_element(p, section_info) }
        each_attr(part, :chapter) { |c| traverse_element(c, section_info) }
        each_attr(part, :appendix) { |a| traverse_element(a, section_info) }
        each_attr(part, :reference) { |r| traverse_element(r, section_info) }
        each_attr(part, :preface) { |p| traverse_element(p, section_info) }
        each_attr(part, :glossary) { |g| traverse_element(g, section_info) }
        each_attr(part, :bibliography) { |b| traverse_element(b, section_info) }
        each_attr(part, :index) { |i| traverse_element(i, section_info) }
        each_attr(part, :setindex) { |si| traverse_element(si, section_info) }
      end

      def traverse_article(article, section_info)
        each_attr(article, :section) { |s| traverse_element(s, section_info) }
        each_attr(article, :glossary) { |g| traverse_element(g, section_info) }
        each_attr(article, :bibliography) { |b| traverse_element(b, section_info) }
        each_attr(article, :index) { |i| traverse_element(i, section_info) }
      end

      def traverse_chapter(chapter, section_info)
        each_attr(chapter, :section) { |s| traverse_element(s, section_info) }
        each_attr(chapter, :simplesect) { |ss| traverse_element(ss, section_info) }
        each_attr(chapter, :para) { |p| traverse_element(p, section_info) }
        each_attr(chapter, :indexterm) { |it| process_indexterm(it, section_info) }
      end

      def traverse_appendix(appendix, section_info)
        each_attr(appendix, :section) { |s| traverse_element(s, section_info) }
        each_attr(appendix, :simplesect) { |ss| traverse_element(ss, section_info) }
        each_attr(appendix, :para) { |p| traverse_element(p, section_info) }
        each_attr(appendix, :indexterm) { |it| process_indexterm(it, section_info) }
      end

      def traverse_section(section, section_info)
        each_attr(section, :section) { |s| traverse_element(s, section_info) }
        each_attr(section, :simplesect) { |ss| traverse_element(ss, section_info) }
        each_attr(section, :para) { |p| traverse_element(p, section_info) }
        each_attr(section, :indexterm) { |it| process_indexterm(it, section_info) }
      end

      def traverse_simplesect(simplesect, section_info)
        each_attr(simplesect, :para) { |p| traverse_element(p, section_info) }
        each_attr(simplesect, :indexterm) { |it| process_indexterm(it, section_info) }
      end

      def traverse_refentry(refentry, section_info)
        each_attr(refentry, :refsection) { |rs| traverse_element(rs, section_info) }
      end

      def traverse_refsection(refsection, section_info)
        new_info = update_section_info(refsection, section_info)
        each_attr(refsection, :para) { |p| traverse_element(p, new_info) }
        each_attr(refsection, :indexterm) { |it| process_indexterm(it, new_info) }
      end

      def traverse_listitem(listitem, section_info)
        each_attr(listitem, :para) { |p| traverse_element(p, section_info) }
        each_attr(listitem, :simplesect) { |ss| traverse_element(ss, section_info) }
        each_attr(listitem, :indexterm) { |it| process_indexterm(it, section_info) }
      end

      def traverse_entry(entry, section_info)
        each_attr(entry, :para) { |p| traverse_element(p, section_info) }
        each_attr(entry, :indexterm) { |it| process_indexterm(it, section_info) }
      end

      def traverse_mixed_content(element, section_info)
        return unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          case node
          when Elements::IndexTerm
            process_indexterm(node, section_info)
          when Elements::Para
            traverse_element(node, section_info)
          end
        end
      end

      def process_indexterm(indexterm, section_info)
        # Skip if no primary (required for meaningful index entry)
        primaries = Array(indexterm.primary).map { |p| p.content.to_s.strip }.compact
        return if primaries.empty?

        primary_text = primaries.first
        secondaries = Array(indexterm.secondary).map { |s| s.content.to_s.strip }.compact
        tertiaries = Array(indexterm.tertiary).map { |t| t.content.to_s.strip }.compact

        sees = Array(indexterm.see).map { |s| s.content.to_s.strip }.compact
        see_alsos = Array(indexterm.see_also).map { |sa| sa.content.to_s.strip }.compact

        term_info = {
          primary: primary_text,
          primary_sort: sort_key(primary_text, indexterm),
          secondary: secondaries.first,
          tertiary: tertiaries.first,
          sees: sees,
          see_alsos: see_alsos,
          type: indexterm.type,
          zone: indexterm.zone,
          xml_id: indexterm.xml_id,
          class_value: indexterm.class_value,
          section_id: section_info[:id],
          section_title: section_info[:title],
          section_info: section_info
        }

        @index_terms << term_info
      end

      def element_title(element)
        case element
        when Elements::Book, Elements::Article
          element.info&.title&.content
        when Elements::Chapter, Elements::Appendix, Elements::Section,
             Elements::Part, Elements::Preface
          element.info&.title&.content || element.title&.content
        when Elements::RefEntry
          element.refnamediv&.refname&.first&.content
        else
          element.title&.content
        end
      end

      # Generate sort key for an index entry
      def sort_key(text, indexterm)
        return "SYMBOLS" if indexterm.class_value == "token" || text.start_with?("@")

        # Remove leading punctuation for sorting
        text.gsub(/^[^a-zA-Z]+/, "").downcase
      end

      # Helper to safely call attributes - same pattern as Html class
      def each_attr(obj, name, &)
        val = obj.send(name)
        return unless val

        Array(val).each(&)
      rescue NoMethodError
        nil
      end
    end

    # Generates index content from collected indexterms
    class IndexGenerator
      def initialize(index_terms, xref_resolver = nil)
        @index_terms = index_terms
        @xref_resolver = xref_resolver
      end

      # Generate index data structure grouped by letter
      def generate
        by_letter = group_by_letter
        by_letter.sort_by { |letter, _| letter == "SYMBOLS" ? "{" : letter.downcase }
                 .to_h
                 .map do |letter, terms|
          {
            letter: letter,
            entries: sort_entries(terms)
          }
        end
      end

      private

      def group_by_letter
        result = {}
        @index_terms.each do |term|
          letter = letter_for(term[:primary_sort])
          result[letter] ||= []
          result[letter] << term
        end
        result
      end

      def letter_for(sort_key)
        return "SYMBOLS" if sort_key == "SYMBOLS" || sort_key.start_with?("@")

        first_char = sort_key.chars.find(&:letter?) || sort_key[0] || ""
        first_char.upcase
      end

      def sort_entries(terms)
        terms.sort_by { |t| [t[:primary_sort], t[:secondary].to_s] }
      end
    end
  end
end
