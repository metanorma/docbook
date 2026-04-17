# frozen_string_literal: true

module Docbook
  module Elements
    class Book < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :version, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :info, Info
      attribute :part, Part, collection: true
      attribute :chapter, Chapter, collection: true
      attribute :appendix, Appendix, collection: true
      attribute :dedication, Dedication, collection: true
      attribute :acknowledgements, Acknowledgements, collection: true
      attribute :preface, Preface, collection: true
      attribute :bibliography, Bibliography, collection: true
      attribute :glossary, Glossary, collection: true
      attribute :index, Index, collection: true
      attribute :colophon, Colophon, collection: true

      xml do
        element "book"
        mixed_content
        map_content to: :content
        map_attribute "version", to: :version
        map_attribute "xml:id", to: :xml_id
        map_element "info", to: :info
        map_element "part", to: :part
        map_element "chapter", to: :chapter
        map_element "appendix", to: :appendix
        map_element "dedication", to: :dedication
        map_element "acknowledgements", to: :acknowledgements
        map_element "preface", to: :preface
        map_element "bibliography", to: :bibliography
        map_element "glossary", to: :glossary
        map_element "index", to: :index
        map_element "colophon", to: :colophon
      end
    end
  end
end
