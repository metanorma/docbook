# frozen_string_literal: true

module Docbook
  module Elements
    class WordAsWord < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "wordasword"
        mixed_content
        map_content to: :content
      end
    end
  end
end
