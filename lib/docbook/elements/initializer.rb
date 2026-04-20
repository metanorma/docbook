# frozen_string_literal: true

module Docbook
  module Elements
    class Initializer < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "initializer"
        mixed_content
        map_content to: :content
      end
    end
  end
end
