# frozen_string_literal: true

module Docbook
  module Elements
    class GlossSeeAlso < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :otherterm, :string

      xml do
        element "glossseealso"
        mixed_content
        map_content to: :content
        map_attribute "otherterm", to: :otherterm
      end
    end
  end
end
