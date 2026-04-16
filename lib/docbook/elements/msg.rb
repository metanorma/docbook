# frozen_string_literal: true

module Docbook
  module Elements
    class Msg < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :main, :string

      xml do
        element "msg"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "main", to: :main
      end
    end
  end
end
