# frozen_string_literal: true

module Docbook
  module Mirror
    class Node
      PM_TYPE = "node"

      attr_accessor :type, :attrs, :content, :marks

      def initialize(type: nil, attrs: {}, content: [], marks: [])
        @type = type || self.class::PM_TYPE
        @attrs = attrs || {}
        @content = content || []
        @marks = marks || []
      end

      # Convert to hash for JSON serialization
      def to_h
        result = { "type" => type }

        result["attrs"] = attrs.transform_keys(&:to_s) if attrs && !attrs.empty?

        if marks && !marks.empty?
          result["marks"] = marks.map do |mark|
            mark.respond_to?(:to_h) ? mark.to_h : mark
          end
        end

        if content && !content.empty?
          result["content"] = content.map do |item|
            item.respond_to?(:to_h) ? item.to_h : item
          end
        end

        result
      end

      alias to_hash to_h

      def to_json(**options)
        to_h.to_json(options)
      end

      def self.from_h(hash)
        return nil unless hash

        type = hash["type"]
        attrs = hash["attrs"] || {}
        content = hash["content"] || []
        marks = hash["marks"] || []

        node_class = NODE_TYPES[type] || Node
        node_class.new(
          attrs: attrs.transform_keys(&:to_sym),
          content: content.map { |c| Node.from_h(c) },
          marks: marks.map { |m| Mark.from_h(m) }
        )
      end

      # Find first node of given type
      def find_first(node_type)
        return self if type == node_type

        content&.each do |child|
          next unless child.is_a?(Node)

          result = child.find_first(node_type)
          return result if result
        end
        nil
      end

      # Find all nodes of given type
      def find_all(node_type)
        results = []
        results << self if type == node_type

        content&.each do |child|
          next unless child.is_a?(Node)

          child_results = child.find_all(node_type)
          results.concat(child_results) if child_results
        end

        results
      end

      # Get text content
      def text_content
        return "" unless content

        content.map do |item|
          if item.is_a?(Node)
            item.text_content
          elsif item.is_a?(String)
            item
          else
            ""
          end
        end.join
      end

      NODE_TYPES = {}.freeze
    end
  end
end
