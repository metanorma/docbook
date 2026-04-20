# frozen_string_literal: true

module Docbook
  module Elements
    class Simplesect < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :programlisting, ProgramListing, collection: true
      attribute :screen, Screen, collection: true
      attribute :literallayout, LiteralLayout, collection: true
      attribute :informalfigure, InformalFigure, collection: true
      attribute :indexterm, IndexTerm, collection: true

      xml do
        element "simplesect"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "programlisting", to: :programlisting
        map_element "screen", to: :screen
        map_element "literallayout", to: :literallayout
        map_element "informalfigure", to: :informalfigure
        map_element "indexterm", to: :indexterm
      end
    end
  end
end
