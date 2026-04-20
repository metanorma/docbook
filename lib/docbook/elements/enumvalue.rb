# frozen_string_literal: true

module Docbook
  module Elements
    class Enumvalue < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "enumvalue"
        mixed_content
        map_content to: :content
      end
    end
  end
end
