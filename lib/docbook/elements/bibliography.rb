# frozen_string_literal: true

module Docbook
  module Elements
    class Bibliography < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :title, Title
      attribute :bibliomixed, Bibliomixed, collection: true

      xml do
        element "bibliography"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "title", to: :title
        map_element "bibliomixed", to: :bibliomixed
      end
    end
  end
end
