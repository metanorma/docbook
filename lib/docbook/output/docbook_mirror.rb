# frozen_string_literal: true

require "json"

module Docbook
  module Output
    # Outputs DocBook document as DocbookMirror (ProseMirror-compatible) JSON.
    #
    # @example
    #   doc = Docbook::Document.from_xml(File.read("book.xml"))
    #   mirror = Docbook::Output::DocbookMirror.new(doc)
    #   json = mirror.to_pretty_json
    class DocbookMirror
      # @param document [Docbook::Elements::Book, Docbook::Elements::Article, etc.] parsed document
      # @param sort_glossary [Boolean] sort glossary entries alphabetically
      def initialize(document, sort_glossary: false)
        @document = document
        @sort_glossary = sort_glossary
      end

      # Returns the DocbookMirror document as a Ruby Hash.
      # @return [Hash]
      def to_document
        transformer = Docbook::Mirror::Transformer.new(sort_glossary: @sort_glossary)
        transformer.from_docbook(@document)
      end

      # Returns the DocbookMirror document as a JSON string.
      # @param options [Hash] JSON generation options
      # @return [String]
      def to_json(**options)
        to_document.to_json(options)
      end

      # Generate pretty-printed JSON.
      # @return [String]
      def to_pretty_json
        to_document.to_json(pretty: true)
      end
    end
  end
end
