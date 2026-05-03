# frozen_string_literal: true

module Docbook
  module Services
    class IndexGenerator
      def initialize(document)
        @document = document
        @entries = []
      end

      def generate
        @entries = []
        collect(@document, {})
        sort_entries!
        @entries
      end

      private

      def collect(element, section_info)
        return unless element

        section_info = extract_section_info(element) if section_info.empty?

        process_index_terms(element, section_info)

        element.walk_children { |child| collect(child, section_info) }
      end

      def extract_section_info(element)
        {
          section_id: element.xml_id || "section-#{element.class.name.split("::").last.downcase}-#{element.object_id}",
          section_title: element.resolve_title,
        }
      end

      def process_index_terms(element, section_info)
        if element.index_term?
          entry = build_index_entry(element, section_info)
          @entries << entry if entry
        end

        Array(element.indexterm).each do |term|
          entry = build_index_entry(term, section_info)
          @entries << entry if entry
        end
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

        entry.secondary = Array(index_term.secondary).filter_map do |s|
          s.content.join
        end
        entry.see_also = Array(index_term.see_also).filter_map do |s|
          s.content.join
        end

        entry
      end

      def extract_primary(index_term)
        if index_term.primary.any?
          Array(index_term.primary).map { |p| p.content.join }.join(" ")
        else
          content = index_term.content
          content.is_a?(Array) ? content.join(" ") : content.to_s
        end
      end

      def sort_entries!
        @entries.sort_by!(&:sort_key)
      end
    end
  end
end
