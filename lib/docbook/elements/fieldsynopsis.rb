# frozen_string_literal: true


module Docbook
  module Elements
    class FieldSynopsis < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :type, :string
      attribute :varname, :string
      attribute :initializer, :string

      xml do
        element "fieldsynopsis"
        map_content to: :content
        map_element "type", to: :type
        map_element "varname", to: :varname
        map_element "initializer", to: :initializer
      end
    end
  end
end