# frozen_string_literal: true


module Docbook
  module Elements
    class Date < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "date"
        mixed_content
        map_content to: :content
      end
    end
  end
end
