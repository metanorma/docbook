# frozen_string_literal: true

module Docbook
  module Elements
    class LiteralLayout < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :width, :string

      xml do
        element "literallayout"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_attribute "width", to: :width
      end
    end
  end
end
