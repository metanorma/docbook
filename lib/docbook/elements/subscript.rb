# frozen_string_literal: true

module Docbook
  module Elements
    class Subscript < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "subscript"
        mixed_content
        map_content to: :content
      end
    end
  end
end
