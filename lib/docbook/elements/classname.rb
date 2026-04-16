# frozen_string_literal: true

module Docbook
  module Elements
    class ClassName < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "classname"
        mixed_content
        map_content to: :content
      end
    end
  end
end
