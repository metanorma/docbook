# frozen_string_literal: true

module Docbook
  module Models
    # Document Metadata - document-level information
    class DocumentMetadata < Lutaml::Model::Serializable
      attribute :author, :string
      attribute :author_name, :string
      attribute :title, :string
      attribute :subtitle, :string
      attribute :productname, :string
      attribute :version, :string
      attribute :pubdate, :string
      attribute :release_info, :string
      attribute :abstract, :string

      json do
        map "author", to: :author
        map "authorName", to: :author_name
        map "title", to: :title
        map "subtitle", to: :subtitle
        map "productname", to: :productname
        map "version", to: :version
        map "pubdate", to: :pubdate
        map "releaseInfo", to: :release_info
        map "abstract", to: :abstract
      end
    end
  end
end
