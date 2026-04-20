# frozen_string_literal: true

module Docbook
  module Elements
    class PubDate < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "pubdate"
        mixed_content
        map_content to: :content
      end
    end
  end
end
