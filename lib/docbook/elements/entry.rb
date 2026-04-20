# frozen_string_literal: true

module Docbook
  module Elements
    class Entry < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :valign, :string
      attribute :align, :string
      attribute :namest, :string
      attribute :nameend, :string
      attribute :colname, :string
      attribute :spanname, :string
      attribute :morerows, :string

      xml do
        element "entry"
        mixed_content
        map_content to: :content
        map_attribute "valign", to: :valign
        map_attribute "align", to: :align
        map_attribute "namest", to: :namest
        map_attribute "nameend", to: :nameend
        map_attribute "colname", to: :colname
        map_attribute "spanname", to: :spanname
        map_attribute "morerows", to: :morerows
      end
    end
  end
end
