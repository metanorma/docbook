# frozen_string_literal: true

module Docbook
  module Elements
    class TocEntry < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :link, Link

      xml do
        element "tocentry"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "link", to: :link
      end
    end
  end
end
