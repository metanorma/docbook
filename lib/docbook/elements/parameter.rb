# frozen_string_literal: true


module Docbook
  module Elements
    class Parameter < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "parameter"
        mixed_content
        map_content to: :content
      end
    end
  end
end
