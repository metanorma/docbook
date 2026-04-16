# frozen_string_literal: true

module Docbook
  module Elements
    class Example < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :label, :string
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :programlisting, ProgramListing, collection: true
      attribute :figure, Figure, collection: true
      attribute :informaltable, InformalTable, collection: true
      attribute :table, Table, collection: true

      xml do
        element "example"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_attribute "label", to: :label
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "programlisting", to: :programlisting
        map_element "figure", to: :figure
        map_element "informaltable", to: :informaltable
        map_element "table", to: :table
      end
    end
  end
end
