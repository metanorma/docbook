# frozen_string_literal: true


module Docbook
  module Elements
    class ProductName < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :class_name, :string

      xml do
        element "productname"
        mixed_content
        map_content to: :content
        map_attribute "class", to: :class_name
      end
    end
  end
end
