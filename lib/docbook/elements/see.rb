# frozen_string_literal: true

module Docbook
  module Elements
    class See < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "see"
        mixed_content
        map_content to: :content
      end
    end
  end
end
