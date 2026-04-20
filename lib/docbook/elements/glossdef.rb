# frozen_string_literal: true

module Docbook
  module Elements
    class GlossDef < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :para, Para, collection: true

      xml do
        element "glossdef"
        mixed_content
        map_content to: :content
        map_element "para", to: :para
      end
    end
  end
end
