# frozen_string_literal: true

require_relative "base"

module Docbook
  module Mirror
    class Node
      class Text < Base
        PM_TYPE = "text"

        attr_accessor :text

        def initialize(text: "", **)
          super(**)
          @text = text
        end

        def to_h
          result = super
          result["text"] = text.to_s
          result
        end

        def text_content
          text.to_s
        end

        def self.from_h(hash)
          return nil unless hash

          new(
            text: hash["text"] || "",
            attrs: (hash["attrs"] || {}).transform_keys(&:to_sym),
            marks: (hash["marks"] || []).map { |m| Docbook::Mirror::Mark.from_h(m) }
          )
        end
      end
    end
  end
end
