# frozen_string_literal: true

module Docbook
  module Elements
    class MediaObject < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :imageobject, ImageObject, collection: true
      attribute :textobject, TextObject, collection: true
      attribute :audioobject, AudioObject, collection: true
      attribute :videoobject, VideoObject, collection: true

      xml do
        element "mediaobject"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "imageobject", to: :imageobject
        map_element "textobject", to: :textobject
        map_element "audioobject", to: :audioobject
        map_element "videoobject", to: :videoobject
      end
    end
  end
end
