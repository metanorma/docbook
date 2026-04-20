# frozen_string_literal: true

module Docbook
  module Elements
    class Attribution < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :personname, PersonName
      attribute :author, Author

      xml do
        element "attribution"
        mixed_content
        map_content to: :content
        map_element "personname", to: :personname
        map_element "author", to: :author
      end
    end
  end
end
