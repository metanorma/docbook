# frozen_string_literal: true

module Docbook
  module Elements
    class RefSection < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :informalfigure, InformalFigure, collection: true
      attribute :indexterm, IndexTerm, collection: true
      attribute :variablelist, VariableList, collection: true
      attribute :programlisting, ProgramListing, collection: true
      attribute :informalexample, InformalExample, collection: true
      attribute :example, Example, collection: true
      attribute :figure, Figure, collection: true
      attribute :orderedlist, OrderedList, collection: true
      attribute :itemizedlist, ItemizedList, collection: true
      attribute :blockquote, BlockQuote, collection: true
      attribute :note, Note, collection: true
      attribute :warning, Warning, collection: true
      attribute :tip, Tip, collection: true
      attribute :caution, Caution, collection: true
      attribute :important, Important, collection: true

      xml do
        element "refsection"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "informalfigure", to: :informalfigure
        map_element "indexterm", to: :indexterm
        map_element "variablelist", to: :variablelist
        map_element "programlisting", to: :programlisting
        map_element "informalexample", to: :informalexample
        map_element "example", to: :example
        map_element "figure", to: :figure
        map_element "orderedlist", to: :orderedlist
        map_element "itemizedlist", to: :itemizedlist
        map_element "blockquote", to: :blockquote
        map_element "note", to: :note
        map_element "warning", to: :warning
        map_element "tip", to: :tip
        map_element "caution", to: :caution
        map_element "important", to: :important
      end
    end
  end
end
