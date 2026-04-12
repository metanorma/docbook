# frozen_string_literal: true


module Docbook
  module Elements
    class IndexTerm < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :zone, :string
      attribute :type, :string
      attribute :class_value, :string
      attribute :primary, Primary, collection: true
      attribute :secondary, Secondary, collection: true
      attribute :tertiary, Tertiary, collection: true
      attribute :see, See, collection: true
      attribute :see_also, SeeAlso, collection: true

      xml do
        element "indexterm"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "zone", to: :zone
        map_attribute "type", to: :type
        map_attribute "class", to: :class_value
        map_element "primary", to: :primary
        map_element "secondary", to: :secondary
        map_element "tertiary", to: :tertiary
        map_element "see", to: :see
        map_element "seealso", to: :see_also
      end
    end
  end
end
