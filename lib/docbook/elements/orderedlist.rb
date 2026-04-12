# frozen_string_literal: true


module Docbook
  module Elements
    class OrderedList < Lutaml::Model::Serializable
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :spacing, :string
      attribute :numeration, :string
      attribute :role, :string
      attribute :listitem, ListItem, collection: true

      xml do
        element "orderedlist"
        map_attribute "xml:id", to: :xml_id
        map_attribute "spacing", to: :spacing
        map_attribute "numeration", to: :numeration
        map_attribute "role", to: :role
        map_element "listitem", to: :listitem
      end
    end
  end
end
