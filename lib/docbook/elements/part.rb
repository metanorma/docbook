# frozen_string_literal: true

module Docbook
  module Elements
    class Part < Lutaml::Model::Serializable
      include HasNumber

      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :version, :string
      attribute :info, Info
      attribute :title, Title
      attribute :preface, Preface, collection: true
      attribute :chapter, Chapter, collection: true
      attribute :appendix, Appendix, collection: true
      attribute :reference, Reference, collection: true
      attribute :glossary, Glossary, collection: true
      attribute :bibliography, Bibliography, collection: true
      attribute :index, Index, collection: true

      xml do
        element "part"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "version", to: :version
        map_element "info", to: :info
        map_element "title", to: :title
        map_element "preface", to: :preface
        map_element "chapter", to: :chapter
        map_element "appendix", to: :appendix
        map_element "reference", to: :reference
        map_element "glossary", to: :glossary
        map_element "bibliography", to: :bibliography
        map_element "index", to: :index
      end
    end
  end
end
