# frozen_string_literal: true

module Docbook
  module Elements
    class Link < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :linkend, :string
      attribute :xlink_href, Lutaml::Xml::W3c::XlinkHrefType
      attribute :xlink_type, Lutaml::Xml::W3c::XlinkTypeAttrType
      attribute :xlink_role, Lutaml::Xml::W3c::XlinkRoleType
      attribute :xlink_title, Lutaml::Xml::W3c::XlinkTitleType

      xml do
        element "link"
        mixed_content
        map_content to: :content
        map_attribute "linkend", to: :linkend
        map_attribute "xlink:href", to: :xlink_href
        map_attribute "xlink:type", to: :xlink_type
        map_attribute "xlink:role", to: :xlink_role
        map_attribute "xlink:title", to: :xlink_title
      end
    end
  end
end
