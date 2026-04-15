# frozen_string_literal: true


module Docbook
  module Elements
    class FieldSynopsis < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :type, Type
      attribute :varname, Varname
      attribute :initializer, Initializer

      xml do
        element "fieldsynopsis"
        mixed_content
        map_content to: :content
        map_element "type", to: :type
        map_element "varname", to: :varname
        map_element "initializer", to: :initializer
      end
    end
  end
end