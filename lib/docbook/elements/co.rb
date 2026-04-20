# frozen_string_literal: true

module Docbook
  module Elements
    class Co < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :label, :string

      xml do
        element "co"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "label", to: :label
      end
    end
  end
end
