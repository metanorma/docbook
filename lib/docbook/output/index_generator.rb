# frozen_string_literal: true

module Docbook
  module Output
    class IndexCollector
      def initialize(document)
        @document = document
        @index_terms = []
      end

      def collect
        @index_terms = []
        traverse(@document, {})
        @index_terms
      end

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

      def traverse(element, section_info)
        return unless element

        section_info = update_section_info(element, section_info)

        Array(element.indexterm).each do |it|
          process_indexterm(it, section_info)
        end

        if element.index_term?
          process_indexterm(element, section_info)
        end

        element.walk_children { |child| traverse(child, section_info) }
      end

      def update_section_info(element, current_info)
        info = current_info.dup
        xml_id = element.xml_id
        if xml_id
          info[:id] = xml_id
          info[:title] = element.resolve_title
        elsif element.titled?
          info[:title] = element.resolve_title
        end
        info
      end

      def process_indexterm(indexterm, section_info)
        primaries = Array(indexterm.primary).filter_map do |p|
          p.content.join.strip
        end
        return if primaries.empty?

        primary_text = primaries.first
        secondaries = Array(indexterm.secondary).filter_map do |s|
          s.content.join.strip
        end
        tertiaries = Array(indexterm.tertiary).filter_map do |t|
          t.content.join.strip
        end

        sees = Array(indexterm.see).filter_map { |s| s.content.join.strip }
        see_alsos = Array(indexterm.see_also).filter_map do |sa|
          sa.content.join.strip
        end

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
          section_info: section_info,
        }

        @index_terms << term_info
      end

      def sort_key(text, indexterm)
        return "SYMBOLS" if indexterm.class_value == "token" || text.start_with?("@")

        text.gsub(/^[^a-zA-Z]+/, "").downcase
      end
    end

    class IndexGenerator
      def initialize(index_terms, xref_resolver = nil)
        @index_terms = index_terms
        @xref_resolver = xref_resolver
      end

      def generate
        by_letter = group_by_letter
        by_letter.sort_by do |letter, _|
          letter == "SYMBOLS" ? "{" : letter.downcase
        end
          .to_h
          .map do |letter, terms|
          {
            letter: letter,
            entries: sort_entries(terms),
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

        first_char = sort_key.chars.find do |c|
          c.match?(/[a-zA-Z]/)
        end || sort_key[0] || ""
        first_char.upcase
      end

      def sort_entries(terms)
        terms.sort_by { |t| [t[:primary_sort], t[:secondary].to_s] }
      end
    end
  end
end
