# frozen_string_literal: true

module Docbook
  module Models
    # DocumentRoot - top-level document structure for Vue SPA
    # Combines Lutaml XML models with Ruby-generated pre-computed data
    class DocumentRoot < Lutaml::Model::Serializable
      attribute :title, :string
      attribute :metadata, DocumentMetadata
      attribute :toc, TocNode, collection: true
      attribute :sections, SectionRoot, collection: true
      attribute :index, IndexEntry, collection: true
      attribute :numbering, SectionNumber, collection: true
      attribute :reading_position, ReadingPosition

      # Version info for debugging
      attribute :generator, :string
      attribute :generated_at, :string

      json do
        map "title", to: :title
        map "metadata", to: :metadata
        map "toc", to: :toc
        map "sections", to: :sections
        map "index", to: :index
        map "numbering", to: :numbering
        map "readingPosition", to: :reading_position
        map "generator", to: :generator
        map "generatedAt", to: :generated_at
      end
    end
  end
end
