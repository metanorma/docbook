# frozen_string_literal: true

module Docbook
  module Elements
    class Article < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :version, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :lang, Lutaml::Xml::W3c::XmlLangType
      attribute :info, Info
      attribute :para, Para, collection: true
      attribute :simplesect, Simplesect, collection: true
      attribute :section, Section, collection: true

      xml do
        element "article"
        mixed_content

        map_content to: :content
        map_attribute "version", to: :version
        map_attribute "xml:id", to: :xml_id
        map_attribute "lang", to: :lang
        map_element "info", to: :info
        map_element "para", to: :para
        map_element "simplesect", to: :simplesect
        map_element "section", to: :section
      end
    end
  end
end
