# frozen_string_literal: true

module Docbook
  module Elements
    class KeyCap < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "keycap"
        mixed_content
        map_content to: :content
      end
    end
  end
end
