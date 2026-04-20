# frozen_string_literal: true

module Docbook
  module Elements
    class Section < Lutaml::Model::Serializable
      include HasNumber

      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :version, :string
      attribute :info, Info
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :section, Section, collection: true
      attribute :simplesect, Simplesect, collection: true
      attribute :formalpara, FormalPara, collection: true
      attribute :orderedlist, OrderedList, collection: true
      attribute :itemizedlist, ItemizedList, collection: true
      attribute :variablelist, VariableList, collection: true
      attribute :figure, Figure, collection: true
      attribute :table, Table, collection: true
      attribute :note, Note, collection: true
      attribute :warning, Warning, collection: true
      attribute :important, Important, collection: true
      attribute :caution, Caution, collection: true
      attribute :tip, Tip, collection: true
      attribute :danger, Danger, collection: true
      attribute :example, Example, collection: true
      attribute :informalfigure, InformalFigure, collection: true
      attribute :programlisting, ProgramListing, collection: true
      attribute :screen, Screen, collection: true
      attribute :literallayout, LiteralLayout, collection: true
      attribute :indexterm, IndexTerm, collection: true
      attribute :bibliolist, Bibliolist, collection: true
      attribute :annotation, Annotation, collection: true
      attribute :qandaset, QandASet, collection: true
      attribute :calloutlist, CalloutList, collection: true
      attribute :sidebar, SideBar, collection: true
      attribute :procedure, Procedure, collection: true
      attribute :footnote, Footnote, collection: true

      xml do
        element "section"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "version", to: :version
        map_element "info", to: :info
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "section", to: :section
        map_element "simplesect", to: :simplesect
        map_element "formalpara", to: :formalpara
        map_element "orderedlist", to: :orderedlist
        map_element "itemizedlist", to: :itemizedlist
        map_element "variablelist", to: :variablelist
        map_element "figure", to: :figure
        map_element "table", to: :table
        map_element "note", to: :note
        map_element "warning", to: :warning
        map_element "important", to: :important
        map_element "caution", to: :caution
        map_element "tip", to: :tip
        map_element "danger", to: :danger
        map_element "example", to: :example
        map_element "informalfigure", to: :informalfigure
        map_element "programlisting", to: :programlisting
        map_element "screen", to: :screen
        map_element "literallayout", to: :literallayout
        map_element "indexterm", to: :indexterm
        map_element "bibliolist", to: :bibliolist
        map_element "annotation", to: :annotation
        map_element "qandaset", to: :qandaset
        map_element "calloutlist", to: :calloutlist
        map_element "sidebar", to: :sidebar
        map_element "procedure", to: :procedure
        map_element "footnote", to: :footnote
      end
    end
  end
end
