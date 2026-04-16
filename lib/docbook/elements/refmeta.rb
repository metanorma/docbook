# frozen_string_literal: true

module Docbook
  module Elements
    class RefMeta < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :manvolnum, :string
      attribute :subtitle, Subtitle
      attribute :productname, ProductName
      attribute :refentrytitle, RefEntryTitle
      attribute :refmiscinfo, RefMiscInfo, collection: true
      attribute :fieldsynopsis, FieldSynopsis, collection: true

      xml do
        element "refmeta"
        mixed_content

        map_content to: :content
        map_element "manvolnum", to: :manvolnum
        map_element "subtitle", to: :subtitle
        map_element "productname", to: :productname
        map_element "refentrytitle", to: :refentrytitle
        map_element "refmiscinfo", to: :refmiscinfo
        map_element "fieldsynopsis", to: :fieldsynopsis
      end
    end
  end
end
