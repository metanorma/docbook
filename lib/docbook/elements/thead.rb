# frozen_string_literal: true


module Docbook
  module Elements
    class THead < Lutaml::Model::Serializable
      attribute :row, Row, collection: true

      xml do
        element "thead"
        map_element "row", to: :row
      end
    end
  end
end
