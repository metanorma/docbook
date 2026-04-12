# frozen_string_literal: true


module Docbook
  module Elements
    class ImageObject < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :imagedata, ImageData
      attribute :alt, Alt

      xml do
        element "imageobject"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "imagedata", to: :imagedata
        map_element "alt", to: :alt
      end
    end
  end
end
