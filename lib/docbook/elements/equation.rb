# frozen_string_literal: true

module Docbook
  module Elements
    class Equation < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :mediaobject, MediaObject, collection: true

      xml do
        element "equation"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "mediaobject", to: :mediaobject
      end
    end
  end
end
