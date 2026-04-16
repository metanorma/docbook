# frozen_string_literal: true

module Docbook
  module Elements
    class Filename < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "filename"
        mixed_content
        map_content to: :content
      end
    end
  end
end
