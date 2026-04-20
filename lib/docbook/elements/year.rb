# frozen_string_literal: true

module Docbook
  module Elements
    class Year < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "year"
        mixed_content
        map_content to: :content
      end
    end
  end
end
