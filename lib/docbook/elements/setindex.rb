# frozen_string_literal: true

module Docbook
  module Elements
    class SetIndex < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :type, :string
      attribute :title, Title
      attribute :indexterm, IndexTerm, collection: true

      xml do
        element "setindex"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "type", to: :type
        map_element "title", to: :title
        map_element "indexterm", to: :indexterm
      end
    end
  end
end
