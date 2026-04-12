# frozen_string_literal: true


module Docbook
  module Elements
    class FirstTerm < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :baseterm, :string

      xml do
        element "firstterm"
        mixed_content
        map_content to: :content
        map_attribute "baseterm", to: :baseterm
      end
    end
  end
end
