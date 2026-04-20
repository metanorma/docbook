# frozen_string_literal: true

module Docbook
  module Elements
    class Footnote < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :label, :string
      attribute :para, Para, collection: true

      xml do
        element "footnote"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "label", to: :label
        map_element "para", to: :para
      end
    end
  end
end
