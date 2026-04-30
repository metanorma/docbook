# frozen_string_literal: true

module Docbook
  module Mirror
    # Bidirectional facade for DocBook <-> DocbookMirror transformation.
    #
    # Delegates to DocbookToMirror (forward) and MirrorToDocbook (reverse).
    # The public API is unchanged:
    #
    #   transformer = Transformer.new
    #   mirror_doc = transformer.from_docbook(docbook_doc)  # -> DocbookMirror
    #   docbook_el = transformer.to_docbook(mirror_node)    # -> DocBook element
    #
    class Transformer
      def initialize(sort_glossary: false)
        @sort_glossary = sort_glossary
      end

      # Convert DocBook document to DocbookMirror
      def from_docbook(docbook_doc)
        DocbookToMirror.new(sort_glossary: @sort_glossary).call(docbook_doc)
      end

      # Convert DocbookMirror node to DocBook element
      def to_docbook(mirror_node)
        MirrorToDocbook.new.call(mirror_node)
      end
    end
  end
end
