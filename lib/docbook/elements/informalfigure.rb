# frozen_string_literal: true

module Docbook
  module Elements
    class InformalFigure < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :mediaobject, MediaObject, collection: true

      xml do
        element "informalfigure"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "mediaobject", to: :mediaobject
      end
    end
  end
end
