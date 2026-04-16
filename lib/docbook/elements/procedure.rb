# frozen_string_literal: true

module Docbook
  module Elements
    class Procedure < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :title, Title
      attribute :step, Step, collection: true

      xml do
        element "procedure"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "title", to: :title
        map_element "step", to: :step
      end
    end
  end
end
