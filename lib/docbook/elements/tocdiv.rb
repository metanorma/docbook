# frozen_string_literal: true


module Docbook
  module Elements
    class TocDiv < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :tocentry, TocEntry, collection: true

      xml do
        element "tocdiv"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "tocentry", to: :tocentry
      end
    end
  end
end
