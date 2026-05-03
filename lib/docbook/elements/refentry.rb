# frozen_string_literal: true

module Docbook
  module Elements
    class RefEntry < Lutaml::Model::Serializable
      include DocbookElement
      include SectionLike
      include TocContainer
      include Titled
      include Identifiable

      def toc_children
        [
          *Array(refsection),
          *Array(refsect1),
          *Array(refsect2),
          *Array(refsect3),
        ]
      end

      def element_id
        id = xml_id
        return id.to_s if id && !id.to_s.empty?

        if refmeta&.fieldsynopsis&.any?
          vn = refmeta.fieldsynopsis.first.varname
          return "p_#{vn.content.join}" if vn&.content&.any?
        end

        "elem-#{object_id}"
      end

      def resolve_title
        if refmeta
          if refmeta.refentrytitle&.content&.any?
            return refmeta.refentrytitle.content.join
          end

          fs = refmeta.fieldsynopsis
          if fs && !fs.empty? && fs.first.varname&.content&.any?
            return fs.first.varname.content.join
          end
        end
        if refnamediv&.refname&.any?
          return refnamediv.refname.map { |n| n.content.join }.join(", ")
        end

        nil
      end

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
