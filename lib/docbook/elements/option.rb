# frozen_string_literal: true

module Docbook
  module Elements
    class Option < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "option"
        mixed_content
        map_content to: :content
      end
    end
  end
end
