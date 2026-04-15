# frozen_string_literal: true


module Docbook
  module Elements
    class ProductName < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :class_name, :string
      attribute :href, :string

      xml do
        element "productname"
        mixed_content
        map_content to: :content
        map_attribute "class", to: :class_name
        map_attribute "xlink:href", to: :href
      end
    end
  end
end
