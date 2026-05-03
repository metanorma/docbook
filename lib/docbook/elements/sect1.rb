# frozen_string_literal: true

module Docbook
  module Elements
    class Sect1 < Lutaml::Model::Serializable
      include DocbookElement
      include SectionLike
      include TocContainer
      include Titled
      include Identifiable
      include Numberable

      NUMBERING_ROLE = :section
      def toc_children
        [
          *Array(section),
          *Array(sect2),
        ]
      end

      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :section, Section, collection: true
      attribute :sect2, Sect2, collection: true

      xml do
        element "sect1"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "section", to: :section
        map_element "sect2", to: :sect2
      end
    end
  end
end
