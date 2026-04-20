# frozen_string_literal: true

module Docbook
  module Elements
    class Property < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "property"
        mixed_content
        map_content to: :content
      end
    end
  end
end
