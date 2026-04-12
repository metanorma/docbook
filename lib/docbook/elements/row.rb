# frozen_string_literal: true


module Docbook
  module Elements
    class Row < Lutaml::Model::Serializable
      attribute :entry, Entry, collection: true

      xml do
        element "row"
        map_element "entry", to: :entry
      end
    end
  end
end
