# frozen_string_literal: true


module Docbook
  module Elements
    class Msgexplan < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :related, :string
      attribute :para, Para, collection: true

      xml do
        element "msgexplan"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "related", to: :related
        map_element "para", to: :para
      end
    end
  end
end
