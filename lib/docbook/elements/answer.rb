# frozen_string_literal: true

module Docbook
  module Elements
    class Answer < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :para, Para, collection: true
      attribute :label, :string

      xml do
        element "answer"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "para", to: :para
        map_element "label", to: :label
      end
    end
  end
end
