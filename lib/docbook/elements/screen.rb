# frozen_string_literal: true


module Docbook
  module Elements
    class Screen < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :language, :string
      attribute :linenumbering, :string
      attribute :continuation, :string
      attribute :format, :string
      attribute :userinput, UserInput, collection: true

      xml do
        element "screen"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "language", to: :language
        map_attribute "linenumbering", to: :linenumbering
        map_attribute "continuation", to: :continuation
        map_attribute "format", to: :format
        map_element "userinput", to: :userinput
      end
    end
  end
end