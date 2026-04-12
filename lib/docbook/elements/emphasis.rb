# frozen_string_literal: true


module Docbook
  module Elements
    class Emphasis < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :role, :string

      xml do
        element "emphasis"
        mixed_content
        map_content to: :content
        map_attribute "role", to: :role
      end
    end
  end
end
