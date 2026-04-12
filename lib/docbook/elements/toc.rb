# frozen_string_literal: true


module Docbook
  module Elements
    class Toc < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :tocdiv, TocDiv, collection: true
      attribute :tocentry, TocEntry, collection: true

      xml do
        element "toc"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "tocdiv", to: :tocdiv
        map_element "tocentry", to: :tocentry
      end
    end
  end
end
