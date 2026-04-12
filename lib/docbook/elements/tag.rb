# frozen_string_literal: true


module Docbook
  module Elements
    class Tag < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :class_name, :string
      attribute :namespace, :string

      xml do
        element "tag"
        mixed_content
        map_content to: :content
        map_attribute "class", to: :class_name
        map_attribute "namespace", to: :namespace
      end
    end
  end
end
