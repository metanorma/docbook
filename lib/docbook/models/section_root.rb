# frozen_string_literal: true

module Docbook
  module Models
    # SectionRoot - wraps a section's XML content with pre-computed metadata
    # This combines the Lutaml model with Ruby-generated data (numbering, etc.)
    class SectionRoot < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :type, :string # chapter, section, appendix, part, reference, refentry
      attribute :title, :string
      attribute :number, :string # Pre-computed number like "I", "1.2", "A"

      # Nested child sections
      attribute :children, SectionRoot, collection: true

      # For reference entries: the refname
      attribute :refname, :string

      json do
        map "id", to: :id
        map "type", to: :type
        map "title", to: :title
        map "number", to: :number
        map "children", to: :children
        map "refname", to: :refname
      end
    end
  end
end
