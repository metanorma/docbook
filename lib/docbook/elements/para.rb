# frozen_string_literal: true


module Docbook
  module Elements
    class Para < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :role, :string
      attribute :productname, ProductName, collection: true
      attribute :link, Link, collection: true
      attribute :emphasis, Emphasis, collection: true
      attribute :code, Code, collection: true
      attribute :literal, Literal, collection: true
      attribute :filename, Filename, collection: true
      attribute :xref, Xref, collection: true
      attribute :parameter, Parameter, collection: true
      attribute :buildtarget, BuildTarget, collection: true
      attribute :dir, Dir, collection: true
      attribute :replaceable, Replaceable, collection: true
      attribute :quote, Quote, collection: true
      attribute :userinput, UserInput, collection: true
      attribute :citetitle, Citetitle, collection: true
      attribute :classname, ClassName, collection: true
      attribute :screen, Screen, collection: true
      attribute :tag, Tag, collection: true
      attribute :att, Att, collection: true
      attribute :biblioref, Biblioref, collection: true
      attribute :glossterm, Glossterm, collection: true
      attribute :firstterm, FirstTerm, collection: true
      attribute :inlinemediaobject, Inlinemediaobject, collection: true
      attribute :indexterm, IndexTerm, collection: true

      xml do
        element "para"
        mixed_content

        map_content to: :content
        map_attribute "role", to: :role
        map_element "productname", to: :productname
        map_element "link", to: :link
        map_element "emphasis", to: :emphasis
        map_element "code", to: :code
        map_element "literal", to: :literal
        map_element "filename", to: :filename
        map_element "xref", to: :xref
        map_element "parameter", to: :parameter
        map_element "buildtarget", to: :buildtarget
        map_element "dir", to: :dir
        map_element "replaceable", to: :replaceable
        map_element "quote", to: :quote
        map_element "userinput", to: :userinput
        map_element "citetitle", to: :citetitle
        map_element "classname", to: :classname
        map_element "screen", to: :screen
        map_element "tag", to: :tag
        map_element "att", to: :att
        map_element "biblioref", to: :biblioref
        map_element "glossterm", to: :glossterm
        map_element "firstterm", to: :firstterm
        map_element "inlinemediaobject", to: :inlinemediaobject
        map_element "indexterm", to: :indexterm
      end
    end
  end
end