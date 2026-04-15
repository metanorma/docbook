# frozen_string_literal: true


module Docbook
  module Elements
    class Appendix < Lutaml::Model::Serializable
      include HasNumber
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :version, :string
      attribute :info, Info
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :section, Section, collection: true
      attribute :literallayout, LiteralLayout, collection: true
      attribute :simplesect, Simplesect, collection: true
      attribute :indexterm, IndexTerm, collection: true

      xml do
        element "appendix"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "version", to: :version
        map_element "info", to: :info
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "section", to: :section
        map_element "literallayout", to: :literallayout
        map_element "simplesect", to: :simplesect
        map_element "indexterm", to: :indexterm
      end
    end
  end
end
