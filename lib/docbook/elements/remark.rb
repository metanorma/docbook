# frozen_string_literal: true

module Docbook
  module Elements
    class Remark < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string

      xml do
        element "remark"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
      end
    end
  end
end
