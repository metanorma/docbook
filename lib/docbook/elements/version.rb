# frozen_string_literal: true

module Docbook
  module Elements
    class Version < Lutaml::Model::Serializable
      include DocbookElement

      attribute :content, :string, collection: true

      xml do
        element "version"
        mixed_content
        map_content to: :content
      end
    end
  end
end
