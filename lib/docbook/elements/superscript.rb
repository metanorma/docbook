# frozen_string_literal: true

module Docbook
  module Elements
    class Superscript < Lutaml::Model::Serializable
      attribute :content, :string, collection: true

      xml do
        element "superscript"
        mixed_content
        map_content to: :content
      end
    end
  end
end
