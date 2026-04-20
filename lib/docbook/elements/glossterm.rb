# frozen_string_literal: true

module Docbook
  module Elements
    class Glossterm < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :baseform, :string

      xml do
        element "glossterm"
        mixed_content
        map_content to: :content
        map_attribute "baseform", to: :baseform
      end
    end
  end
end
