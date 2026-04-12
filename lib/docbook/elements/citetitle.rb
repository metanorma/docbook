# frozen_string_literal: true


module Docbook
  module Elements
    class Citetitle < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :role, :string
      attribute :href, :xlink_href

      xml do
        element "citetitle"
        mixed_content
        map_content to: :content
        map_attribute "role", to: :role
        map_attribute "href", to: :href
      end
    end
  end
end