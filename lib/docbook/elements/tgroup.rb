# frozen_string_literal: true

module Docbook
  module Elements
    class TGroup < Lutaml::Model::Serializable
      attribute :cols, :string
      attribute :thead, THead
      attribute :tbody, TBody
      attribute :tfoot, TFoot

      xml do
        element "tgroup"
        map_attribute "cols", to: :cols
        map_element "thead", to: :thead
        map_element "tbody", to: :tbody
        map_element "tfoot", to: :tfoot
      end
    end
  end
end
