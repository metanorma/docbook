# frozen_string_literal: true

module Docbook
  module Elements
    class Quote < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :replaceable, Replaceable, collection: true
      attribute :literal, Literal, collection: true
      attribute :code, Code, collection: true
      attribute :emphasis, Emphasis, collection: true
      attribute :link, Link, collection: true
      attribute :xref, Xref, collection: true
      attribute :filename, Filename, collection: true
      attribute :classname, ClassName, collection: true
      attribute :function, Function, collection: true
      attribute :parameter, Parameter, collection: true
      attribute :att, Att, collection: true
      attribute :tag, Tag, collection: true
      attribute :userinput, UserInput, collection: true
      attribute :screen, Screen, collection: true
      attribute :citetitle, Citetitle, collection: true
      attribute :biblioref, Biblioref, collection: true
      attribute :firstterm, FirstTerm, collection: true
      attribute :glossterm, Glossterm, collection: true
      attribute :inlinemediaobject, Inlinemediaobject, collection: true

      xml do
        element "quote"
        mixed_content
        map_content to: :content
        map_element "replaceable", to: :replaceable
        map_element "literal", to: :literal
        map_element "code", to: :code
        map_element "emphasis", to: :emphasis
        map_element "link", to: :link
        map_element "xref", to: :xref
        map_element "filename", to: :filename
        map_element "classname", to: :classname
        map_element "function", to: :function
        map_element "parameter", to: :parameter
        map_element "att", to: :att
        map_element "tag", to: :tag
        map_element "userinput", to: :userinput
        map_element "screen", to: :screen
        map_element "citetitle", to: :citetitle
        map_element "biblioref", to: :biblioref
        map_element "firstterm", to: :firstterm
        map_element "glossterm", to: :glossterm
        map_element "inlinemediaobject", to: :inlinemediaobject
      end
    end
  end
end
