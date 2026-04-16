# frozen_string_literal: true

module Docbook
  module Elements
    class GlossSee < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :otherterm, :string

      xml do
        element "glosssee"
        mixed_content
        map_content to: :content
        map_attribute "otherterm", to: :otherterm
      end
    end
  end
end
