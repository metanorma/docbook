# frozen_string_literal: true

module Docbook
  module Models
    # Index Entry - represents a single entry in the generated index
    class IndexEntry < Lutaml::Model::Serializable
      attribute :primary, :string
      attribute :secondary, :string, collection: true
      attribute :tertiary, :string, collection: true
      attribute :see_also, :string, collection: true
      attribute :section_id, :string
      attribute :section_title, :string

      # Sort key for alphabetical ordering (lowercased, stripped)
      attribute :sort_key, :string

      json do
        map "primary", to: :primary
        map "secondary", to: :secondary
        map "tertiary", to: :tertiary
        map "seeAlso", to: :see_also
        map "sectionId", to: :section_id
        map "sectionTitle", to: :section_title
        map "sortKey", to: :sort_key
      end
    end
  end
end
