# frozen_string_literal: true

module Docbook
  module Elements
    class ForeignPhrase < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :role, :string

      xml do
        element "foreignphrase"
        mixed_content
        map_content to: :content
        map_attribute "role", to: :role
      end
    end
  end
end
