# frozen_string_literal: true

module Docbook
  module Elements
    class Exceptionname < Lutaml::Model::Serializable
      include DocbookElement

      attribute :content, :string, collection: true

      xml do
        element "exceptionname"
        mixed_content
        map_content to: :content
      end
    end
  end
end
