# frozen_string_literal: true

module Docbook
  module Elements
    class FootnoteRef < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :endterm, :string
      attribute :linkend, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType

      xml do
        element "footnoteref"
        map_content to: :content
        map_attribute "endterm", to: :endterm
        map_attribute "linkend", to: :linkend
        map_attribute "xml:id", to: :xml_id
      end
    end
  end
end
