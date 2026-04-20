# frozen_string_literal: true

module Docbook
  module Elements
    class Table < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :tabstyle, :string
      attribute :title, Title
      attribute :tgroup, TGroup, collection: true

      xml do
        element "table"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "tabstyle", to: :tabstyle
        map_element "title", to: :title
        map_element "tgroup", to: :tgroup
      end
    end
  end
end
