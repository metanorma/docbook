# frozen_string_literal: true


module Docbook
  module Elements
    class InformalTable < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :frame, :string
      attribute :colsep, :string
      attribute :rowsep, :string
      attribute :tgroup, TGroup, collection: true

      xml do
        element "informaltable"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "frame", to: :frame
        map_attribute "colsep", to: :colsep
        map_attribute "rowsep", to: :rowsep
        map_element "tgroup", to: :tgroup
      end
    end
  end
end
