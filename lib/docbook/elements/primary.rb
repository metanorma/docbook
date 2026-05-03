# frozen_string_literal: true

module Docbook
  module Elements
    class Primary < Lutaml::Model::Serializable
      include DocbookElement

      attribute :content, :string, collection: true

      xml do
        element "primary"
        mixed_content
        map_content to: :content
      end
    end
  end
end
