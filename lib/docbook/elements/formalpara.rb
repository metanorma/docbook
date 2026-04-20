# frozen_string_literal: true

module Docbook
  module Elements
    class FormalPara < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :title, Title
      attribute :para, Para

      xml do
        element "formalpara"
        mixed_content
        map_content to: :content
        map_element "title", to: :title
        map_element "para", to: :para
      end
    end
  end
end
