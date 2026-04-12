# frozen_string_literal: true


module Docbook
  module Elements
    class UserInput < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType

      xml do
        element "userinput"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
      end
    end
  end
end
