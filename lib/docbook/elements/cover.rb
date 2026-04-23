# frozen_string_literal: true

module Docbook
  module Elements
    class Cover < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :mediaobject, MediaObject, collection: true

      xml do
        element "cover"
        mixed_content
        map_content to: :content
        map_element "mediaobject", to: :mediaobject
      end
    end
  end
end
