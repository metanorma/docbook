# frozen_string_literal: true


module Docbook
  module Elements
    class TBody < Lutaml::Model::Serializable
      attribute :row, Row, collection: true

      xml do
        element "tbody"
        map_element "row", to: :row
      end
    end
  end
end
