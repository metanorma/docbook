# frozen_string_literal: true

module Docbook
  module Elements
    class GlossEntry < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :glossterm, Glossterm
      attribute :glossdef, GlossDef
      attribute :glosssee, GlossSee, collection: true
      attribute :glossseealso, GlossSeeAlso, collection: true

      xml do
        element "glossentry"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "glossterm", to: :glossterm
        map_element "glossdef", to: :glossdef
        map_element "glosssee", to: :glosssee
        map_element "glossseealso", to: :glossseealso
      end
    end
  end
end
