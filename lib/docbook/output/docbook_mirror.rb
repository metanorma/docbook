# frozen_string_literal: true

require "json"

module Docbook
  module Output
    # Outputs DocBook document as DocbookMirror (ProseMirror-compatible) JSON
    class DocbookMirror
      def initialize(document, **options)
        @document = document
        @options = options
      end

      # Returns the DocbookMirror document as a Ruby object
      def to_document
        transformer = Docbook::Mirror::Transformer.new
        transformer.from_docbook(@document)
      end

      # Returns the DocbookMirror document as JSON string
      def to_json(**options)
        to_document.to_json(options)
      end

      # Generate pretty-printed JSON (default)
      def to_pretty_json
        to_document.to_json(pretty: true)
      end
    end
  end
end
