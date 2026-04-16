# frozen_string_literal: true

module Docbook
  module Elements
    class Title < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "title"
        mixed_content
        map_content to: :content
      end
    end
  end
end
