# frozen_string_literal: true


module Docbook
  module Elements
    class IndexEntry < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :primaryie, :string
      attribute :secondaryie, :string

      xml do
        element "indexentry"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "primaryie", to: :primaryie
        map_element "secondaryie", to: :secondaryie
      end
    end
  end
end
