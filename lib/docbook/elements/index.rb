# frozen_string_literal: true


module Docbook
  module Elements
    class Index < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :type, :string
      attribute :title, Title
      attribute :indexdiv, IndexDiv, collection: true
      attribute :indexentry, IndexEntry, collection: true

      xml do
        element "index"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "type", to: :type
        map_element "title", to: :title
        map_element "indexdiv", to: :indexdiv
        map_element "indexentry", to: :indexentry
      end
    end
  end
end
