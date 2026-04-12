# frozen_string_literal: true


module Docbook
  module Elements
    class Subtitle < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "subtitle"
        mixed_content
        map_content to: :content
      end
    end
  end
end
