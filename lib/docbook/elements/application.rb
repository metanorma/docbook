# frozen_string_literal: true

module Docbook
  module Elements
    class Application < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "application"
        mixed_content
        map_content to: :content
      end
    end
  end
end
