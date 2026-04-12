# frozen_string_literal: true


module Docbook
  module Elements
    class CalloutList < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :callout, Callout, collection: true

      xml do
        element "calloutlist"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "callout", to: :callout
      end
    end
  end
end
