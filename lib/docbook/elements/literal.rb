# frozen_string_literal: true


module Docbook
  module Elements
    class Literal < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "literal"
        mixed_content
        map_content to: :content
      end
    end
  end
end
