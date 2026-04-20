# frozen_string_literal: true

module Docbook
  module Elements
    class Author < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :personname, PersonName

      xml do
        element "author"
        mixed_content
        map_content to: :content
        map_element "personname", to: :personname
      end
    end
  end
end
