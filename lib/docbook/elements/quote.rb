# frozen_string_literal: true


module Docbook
  module Elements
    class Quote < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :replaceable, Replaceable, collection: true

      xml do
        element "quote"
        mixed_content
        map_content to: :content
        map_element "replaceable", to: :replaceable
      end
    end
  end
end