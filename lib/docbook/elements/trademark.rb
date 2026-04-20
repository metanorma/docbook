# frozen_string_literal: true

module Docbook
  module Elements
    class Trademark < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :class_name, :string

      xml do
        element "trademark"
        mixed_content
        map_content to: :content
        map_attribute "class", to: :class_name
      end
    end
  end
end
