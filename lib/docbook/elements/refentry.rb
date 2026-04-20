# frozen_string_literal: true

module Docbook
  module Elements
    class RefEntry < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :refmeta, RefMeta
      attribute :refnamediv, RefNamediv
      attribute :refsection, RefSection, collection: true
      attribute :refsect1, RefSect1, collection: true
      attribute :refsect2, RefSect2, collection: true
      attribute :refsect3, RefSect3, collection: true
      attribute :informalfigure, InformalFigure, collection: true

      xml do
        element "refentry"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "refmeta", to: :refmeta
        map_element "refnamediv", to: :refnamediv
        map_element "refsection", to: :refsection
        map_element "refsect1", to: :refsect1
        map_element "refsect2", to: :refsect2
        map_element "refsect3", to: :refsect3
        map_element "informalfigure", to: :informalfigure
      end
    end
  end
end
