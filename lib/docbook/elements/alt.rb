# frozen_string_literal: true

module Docbook
  module Elements
    class Alt < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "alt"
        mixed_content
        map_content to: :content
      end
    end
  end
end
