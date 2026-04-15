# frozen_string_literal: true

module Docbook
  module Elements
    class Prompt < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "prompt"
        mixed_content
        map_content to: :content
      end
    end
  end
end
