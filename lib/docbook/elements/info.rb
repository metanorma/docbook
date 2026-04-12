# frozen_string_literal: true


module Docbook
  module Elements
    class Info < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :title, Title
      attribute :doc_date, Docbook::Elements::Date
      attribute :author, Author, collection: true
      attribute :productname, ProductName, collection: true

      xml do
        element "info"
        mixed_content

        map_content to: :content
        map_element "title", to: :title
        map_element "date", to: :doc_date
        map_element "author", to: :author
        map_element "productname", to: :productname
      end
    end
  end
end
