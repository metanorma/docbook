# frozen_string_literal: true


module Docbook
  module Elements
    class ItemizedList < Lutaml::Model::Serializable
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :mark, :string
      attribute :listitem, ListItem, collection: true

      xml do
        element "itemizedlist"
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_attribute "mark", to: :mark
        map_element "listitem", to: :listitem
      end
    end
  end
end
