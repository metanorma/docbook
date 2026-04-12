# frozen_string_literal: true


module Docbook
  module Elements
    class VariableList < Lutaml::Model::Serializable
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :varlistentry, Varlistentry, collection: true

      xml do
        element "variablelist"
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "varlistentry", to: :varlistentry
      end
    end
  end
end
