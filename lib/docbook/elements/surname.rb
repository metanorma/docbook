# frozen_string_literal: true


module Docbook
  module Elements
    class Surname < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "surname"
        mixed_content
        map_content to: :content
      end
    end
  end
end
