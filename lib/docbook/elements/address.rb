# frozen_string_literal: true

module Docbook
  module Elements
    class Address < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType

      xml do
        element "address"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
      end
    end
  end
end
