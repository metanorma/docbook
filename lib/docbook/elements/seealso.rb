# frozen_string_literal: true

module Docbook
  module Elements
    class SeeAlso < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :endterm, :string

      xml do
        element "seealso"
        mixed_content
        map_content to: :content
        map_attribute "endterm", to: :endterm
      end
    end
  end
end
