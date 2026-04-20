# frozen_string_literal: true

module Docbook
  module Elements
    class Dir < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "dir"
        mixed_content
        map_content to: :content
      end
    end
  end
end
