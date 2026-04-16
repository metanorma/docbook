# frozen_string_literal: true

module Docbook
  module Elements
    class BlockQuote < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :title, Title
      attribute :attribution, Attribution
      attribute :para, Para, collection: true

      xml do
        element "blockquote"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "title", to: :title
        map_element "attribution", to: :attribution
        map_element "para", to: :para
      end
    end
  end
end
