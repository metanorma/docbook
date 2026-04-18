# frozen_string_literal: true

module Docbook
  module Services
    # Generates lists of figures, tables, and examples with section context.
    class ListOfGenerator
      # Struct for a list entry with id, title, number, and section context
      Entry = Struct.new(:id, :title, :number, :section_id, :section_title, keyword_init: true)

      TYPES = {
        figures: [Elements::Figure, Elements::InformalFigure],
        tables: [Elements::Table, Elements::InformalTable],
        examples: [Elements::Example, Elements::InformalExample],
      }.freeze

      # @param document [Docbook::Elements::Book, Docbook::Elements::Article, etc.] parsed document
      def initialize(document)
        @document = document
      end

      # @param numbering [Hash<String, String>] id-to-number map from {NumberingService}
      # @return [Hash{Symbol => Array<Entry>}]
      def generate(numbering: {})
        result = {}
        TYPES.each do |type_name, element_types|
          entries = []
          collect(@document, entries, element_types, numbering)
          result[type_name] = entries if entries.any?
        end
        result
      end

      private

      def collect(node, entries, types, numbering, section_id = nil, section_title = nil)
        if node.is_a?(Elements::Section) || node.is_a?(Elements::Chapter) ||
            node.is_a?(Elements::Part) || node.is_a?(Elements::Appendix) ||
            node.is_a?(Elements::Preface) || node.is_a?(Elements::Reference)
          section_id = node.xml_id if node.respond_to?(:xml_id)
          section_title = extract_title(node) || section_title
        end

        if types.any? { |t| node.is_a?(t) }
          title = extract_title(node)
          if title
            xml_id = node.respond_to?(:xml_id) ? node.xml_id : nil
            number = xml_id ? numbering[xml_id] : nil
            entries << Entry.new(
              id: xml_id,
              title: title,
              number: number,
              section_id: section_id,
              section_title: section_title,
            )
          end
        end

        return unless node.class.respond_to?(:attributes)

        node.class.attributes.each_value do |attr_def|
          value = node.send(attr_def.name)
          next if value.nil?

          case value
          when Array
            value.each { |v| collect(v, entries, types, numbering, section_id, section_title) if walkable?(v) }
          else
            collect(value, entries, types, numbering, section_id, section_title) if walkable?(value)
          end
        end
      end

      def walkable?(value)
        value.is_a?(Lutaml::Model::Serializable)
      end

      def extract_title(node)
        return nil unless node.respond_to?(:title)

        title = node.title
        return nil unless title

        content = title.content
        return nil unless content

        text = content.is_a?(Array) ? content.join : content.to_s
        text.strip.empty? ? nil : text.strip
      end
    end
  end
end
