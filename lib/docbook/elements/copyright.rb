# frozen_string_literal: true


module Docbook
  module Elements
    class Copyright < Lutaml::Model::Serializable
      attribute :year, Year, collection: true
      attribute :holder, Holder, collection: true

      xml do
        element "copyright"
        map_element "year", to: :year
        map_element "holder", to: :holder
      end
    end
  end
end
