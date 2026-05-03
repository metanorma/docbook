# frozen_string_literal: true

module Docbook
  module Services
    class ListOfGenerator
      Entry = Struct.new(:id, :title, :number, :section_id, :section_title,
                         keyword_init: true)

      def initialize(document)
        @document = document
      end

      def generate(numbering: {})
        buckets = {}
        collect(@document, buckets, numbering, nil, nil)
        buckets.reject { |_, v| v.empty? }
      end

      private

      def collect(node, buckets, numbering, section_id, section_title)
        if node.section_like?
          section_id = node.xml_id if node.xml_id
          section_title = node.resolve_title || section_title
        end

        cat = node.list_of_category
        if cat
          title = node.resolve_title
          if title
            buckets[cat] ||= []
            xml_id = node.xml_id
            number = xml_id ? numbering[xml_id] : nil
            buckets[cat] << Entry.new(
              id: xml_id,
              title: title,
              number: number,
              section_id: section_id,
              section_title: section_title,
            )
          end
        end

        node.walk_children do |child|
          collect(child, buckets, numbering, section_id, section_title)
        end
      end
    end
  end
end
