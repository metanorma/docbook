# frozen_string_literal: true

module Docbook
  module Elements
    class Varname < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "varname"
        mixed_content
        map_content to: :content
      end
    end
  end
end
