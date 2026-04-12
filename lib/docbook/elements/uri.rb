# frozen_string_literal: true


module Docbook
  module Elements
    class Uri < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "uri"
        mixed_content
        map_content to: :content
      end
    end
  end
end
