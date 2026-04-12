# frozen_string_literal: true


module Docbook
  module Elements
    class Biblioref < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :linkend, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType

      xml do
        element "biblioref"
        mixed_content
        map_content to: :content
        map_attribute "linkend", to: :linkend
        map_attribute "xml:id", to: :xml_id
      end
    end
  end
end
