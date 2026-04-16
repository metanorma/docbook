# frozen_string_literal: true

module Docbook
  module Elements
    class TFoot < Lutaml::Model::Serializable
      attribute :row, Row, collection: true

      xml do
        element "tfoot"
        map_element "row", to: :row
      end
    end
  end
end
