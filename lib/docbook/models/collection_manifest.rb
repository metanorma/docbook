# frozen_string_literal: true

module Docbook
  module Models
    class CollectionManifest < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :description, :string
      attribute :books, BookEntry, collection: true

      json do
        map "name", to: :name
        map "description", to: :description
        map "books", to: :books
      end
    end
  end
end
