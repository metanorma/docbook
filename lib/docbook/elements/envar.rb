# frozen_string_literal: true

module Docbook
  module Elements
    class Envar < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "envar"
        mixed_content
        map_content to: :content
      end
    end
  end
end
