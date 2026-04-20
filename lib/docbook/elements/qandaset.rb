# frozen_string_literal: true

module Docbook
  module Elements
    class QandASet < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :qandaentry, QandAEntry, collection: true

      xml do
        element "qandaset"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "qandaentry", to: :qandaentry
      end
    end
  end
end
