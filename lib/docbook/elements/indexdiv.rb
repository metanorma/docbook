# frozen_string_literal: true

module Docbook
  module Elements
    class IndexDiv < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :indexentry, IndexEntry, collection: true

      xml do
        element "indexdiv"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "indexentry", to: :indexentry
      end
    end
  end
end
