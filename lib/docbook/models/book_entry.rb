# frozen_string_literal: true

module Docbook
  module Models
    class BookEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :source, :string
      attribute :title, :string
      attribute :author, :string
      attribute :description, :string
      attribute :cover, :string

      json do
        map "id", to: :id
        map "source", to: :source
        map "title", to: :title
        map "author", to: :author
        map "description", to: :description
        map "cover", to: :cover
      end
    end
  end
end
