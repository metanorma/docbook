# frozen_string_literal: true

module Docbook
  module Mirror
    class Mark
      PM_TYPE = "mark"

      attr_accessor :type, :attrs

      def initialize(type: nil, attrs: {})
        @type = type || self.class::PM_TYPE
        @attrs = attrs || {}
      end

      def to_h
        result = { "type" => type }
        result["attrs"] = attrs.transform_keys(&:to_s) if attrs && !attrs.empty?
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

        mark_class = MARK_TYPES[type] || Mark
        mark_class.new(
          attrs: attrs.transform_keys(&:to_sym)
        )
      end

      MARK_TYPES = {}.freeze
    end
  end
end
