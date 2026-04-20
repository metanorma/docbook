# frozen_string_literal: true

module Docbook
  module Elements
    class Term < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :code, Code, collection: true
      attribute :literal, Literal, collection: true
      attribute :emphasis, Emphasis, collection: true
      attribute :filename, Filename, collection: true
      attribute :productname, ProductName, collection: true
      attribute :link, Link, collection: true
      attribute :xref, Xref, collection: true
      attribute :tag, Tag, collection: true
      attribute :att, Att, collection: true
      attribute :property, Property, collection: true

      xml do
        element "term"
        mixed_content

        map_content to: :content
        map_element "code", to: :code
        map_element "literal", to: :literal
        map_element "emphasis", to: :emphasis
        map_element "filename", to: :filename
        map_element "productname", to: :productname
        map_element "link", to: :link
        map_element "xref", to: :xref
        map_element "tag", to: :tag
        map_element "att", to: :att
        map_element "property", to: :property
      end
    end
  end
end
