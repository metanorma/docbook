# frozen_string_literal: true

module Docbook
  module Elements
    class Sect3 < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :sect4, Sect4, collection: true

      xml do
        element "sect3"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "sect4", to: :sect4
      end
    end
  end
end
