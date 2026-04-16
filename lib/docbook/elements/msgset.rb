# frozen_string_literal: true

module Docbook
  module Elements
    class MsgSet < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :msg, Msg, collection: true
      attribute :msgexplan, Msgexplan, collection: true

      xml do
        element "msgset"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "msg", to: :msg
        map_element "msgexplan", to: :msgexplan
      end
    end
  end
end
