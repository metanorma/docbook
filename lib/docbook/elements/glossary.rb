# frozen_string_literal: true

module Docbook
  module Elements
    class Glossary < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :title, Title
      attribute :glossentry, GlossEntry, collection: true

      xml do
        element "glossary"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "title", to: :title
        map_element "glossentry", to: :glossentry
      end
    end
  end
end
