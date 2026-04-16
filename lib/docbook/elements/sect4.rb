# frozen_string_literal: true

module Docbook
  module Elements
    class Sect4 < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :sect5, Sect5, collection: true

      xml do
        element "sect4"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "sect5", to: :sect5
      end
    end
  end
end
