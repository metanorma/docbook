# frozen_string_literal: true

module Docbook
  module Elements
    class Figure < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :title, Title
      attribute :mediaobject, MediaObject, collection: true
      attribute :programlisting, ProgramListing
      attribute :screen, Screen

      xml do
        element "figure"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "title", to: :title
        map_element "mediaobject", to: :mediaobject
        map_element "programlisting", to: :programlisting
        map_element "screen", to: :screen
      end
    end
  end
end
