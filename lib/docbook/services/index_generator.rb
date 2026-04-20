# frozen_string_literal: true

module Docbook
  module Services
    # Generates index entries from IndexTerm elements in the document
    class IndexGenerator
      def initialize(document)
        @document = document
        @entries = []
      end

      def generate
        @entries = []
        collect_index_terms(@document)
        sort_entries!
        @entries
      end

      private

      def collect_index_terms(element, section_info = {})
        return unless element

        # Extract section info from current element
        section_info = extract_section_info(element) if section_info.empty?

        # Process index terms at this level
        process_index_terms(element, section_info)

        # Recurse into children
        if element.respond_to?(:elements)
          Array(element.elements).each do |child|
            collect_index_terms(child, section_info)
          end
        end

        # Process nested sections
        return unless element.respond_to?(:section)

        Array(element.section).each do |section|
          collect_index_terms(section, section_info)
        end
      end

      def extract_section_info(element)
        {
          section_id: element.xml_id || generate_id(element),
          section_title: get_element_title(element),
        }
      end

      def get_element_title(element)
        case element
        when Elements::RefEntry
          element.refnamediv&.refname&.map { |r| r.content.join }&.join(" ") ||
            element.refmeta&.refentrytitle&.content&.join
        else
          (element.respond_to?(:title) && element.title&.content&.join) ||
            (element.respond_to?(:info) && element.info&.title&.content&.join)
        end
      end

      def generate_id(element)
        "section-#{element.class.name.split("::").last.downcase}-#{element.object_id}"
      end

      def process_index_terms(element, section_info)
        # Find indexterm elements
        index_terms = find_index_terms(element)

        index_terms.each do |term|
          entry = build_index_entry(term, section_info)
          @entries << entry if entry
        end
      end

      def find_index_terms(element)
        return [] unless element

        terms = []
        terms << element if element.is_a?(Elements::IndexTerm)

        # Check for nested index terms
        terms.concat(Array(element.indexterm)) if element.respond_to?(:indexterm)

        terms
      end

      def build_index_entry(index_term, section_info)
        primary = extract_primary(index_term)
        return nil unless primary

        entry = Models::IndexEntry.new(
          primary: primary,
          section_id: section_info[:section_id],
          section_title: section_info[:section_title],
          sort_key: primary.downcase.strip,
        )

        # Extract secondary terms
        entry.secondary = Array(index_term.secondary).filter_map { |s| s.content.join } if index_term.respond_to?(:secondary)

        # Extract see-also
        entry.see_also = Array(index_term.see_also).filter_map { |s| s.content.join } if index_term.respond_to?(:see_also)

        entry
      end

      def extract_primary(index_term)
        # Primary is typically in the content or primary attribute
        if index_term.respond_to?(:primary) && index_term.primary
          Array(index_term.primary).map { |p| p.content.join }.join(" ")
        elsif index_term.respond_to?(:content)
          content = index_term.content
          content.is_a?(Array) ? content.join(" ") : content.to_s
        elsif index_term.respond_to?(:to_s)
          index_term.to_s
        end
      end

      def sort_entries!
        @entries.sort_by!(&:sort_key)
      end
    end
  end
end
