# frozen_string_literal: true

module Docbook
  module Elements
    class Topic < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :version, :string
      attribute :info, Info
      attribute :title, Title
      attribute :para, Para, collection: true

      xml do
        element "topic"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "version", to: :version
        map_element "info", to: :info
        map_element "title", to: :title
        map_element "para", to: :para
      end
    end
  end
end
