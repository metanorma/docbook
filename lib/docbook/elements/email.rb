# frozen_string_literal: true

module Docbook
  module Elements
    class Email < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "email"
        mixed_content
        map_content to: :content
      end
    end
  end
end
