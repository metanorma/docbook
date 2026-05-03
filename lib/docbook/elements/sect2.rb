# frozen_string_literal: true

module Docbook
  module Elements
    class Sect2 < Lutaml::Model::Serializable
      include DocbookElement
      include SectionLike
      include TocContainer
      include Titled
      include Identifiable
      include Numberable

      NUMBERING_ROLE = :section
      def toc_children
        Array(sect3)
      end

      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :sect3, Sect3, collection: true

      xml do
        element "sect2"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "sect3", to: :sect3
      end
    end
  end
end
