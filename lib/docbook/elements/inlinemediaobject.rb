# frozen_string_literal: true

module Docbook
  module Elements
    class Inlinemediaobject < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :imageobject, ImageObject
      attribute :textobject, TextObject
      attribute :alt, Alt

      xml do
        element "inlinemediaobject"
        mixed_content
        map_content to: :content
        map_element "imageobject", to: :imageobject
        map_element "textobject", to: :textobject
        map_element "alt", to: :alt
      end
    end
  end
end
