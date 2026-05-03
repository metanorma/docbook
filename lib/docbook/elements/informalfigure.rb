# frozen_string_literal: true

module Docbook
  module Elements
    class InformalFigure < Lutaml::Model::Serializable
      include DocbookElement
      include Identifiable

      STATS_CATEGORY = :image

      def stats_category
        STATS_CATEGORY
      end

      include Numberable

      NUMBERING_ROLE = :figure
      LIST_OF_CATEGORY = :figures

      def formal?
        true
      end

      def list_of_category
        LIST_OF_CATEGORY
      end

      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :mediaobject, MediaObject, collection: true

      xml do
        element "informalfigure"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "mediaobject", to: :mediaobject
      end
    end
  end
end
