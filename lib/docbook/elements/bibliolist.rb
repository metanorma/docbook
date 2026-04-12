# frozen_string_literal: true

module Docbook
  module Elements
    class Bibliolist < Lutaml::Model::Serializable
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :bibliomixed, Bibliomixed, collection: true

      xml do
        element "bibliolist"
        mixed_content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "bibliomixed", to: :bibliomixed
      end
    end
  end
end
