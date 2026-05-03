# frozen_string_literal: true

module Docbook
  module Services
    class TocGenerator
      def initialize(document)
        @document = document
      end

      def generate
        @document.toc_children.filter_map { |element| build_toc_node(element) }
      end

      private

      def build_toc_node(element)
        return nil unless element.titled?

        node = Models::TocNode.new(
          id: element.element_id,
          title: get_title(element),
          type: element_type(element),
          number: nil,
        )

        children = element.toc_children
        if children.any?
          node.children = children.filter_map do |child|
            build_toc_node(child)
          end
        end

        node
      end

      def get_title(element)
        title = element.resolve_title
        title && !title.empty? ? title : "Untitled"
      end

      def element_type(element)
        element.class.name.split("::").last.downcase
      end
    end
  end
end
