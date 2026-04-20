# frozen_string_literal: true

module Docbook
  module Elements
    class ProgramListing < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :language, :string
      attribute :linenumbering, :string
      attribute :startinglinenumber, :string
      attribute :continuation, :string
      attribute :format, :string
      attribute :co, Co, collection: true

      xml do
        element "programlisting"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "language", to: :language
        map_attribute "linenumbering", to: :linenumbering
        map_attribute "startinglinenumber", to: :startinglinenumber
        map_attribute "continuation", to: :continuation
        map_attribute "format", to: :format
        map_element "co", to: :co
      end
    end
  end
end
