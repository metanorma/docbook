# frozen_string_literal: true

module Docbook
  module Elements
    class Callout < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :arearefs, :string
      attribute :para, Para, collection: true

      xml do
        element "callout"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "arearefs", to: :arearefs
        map_element "para", to: :para
      end
    end
  end
end
