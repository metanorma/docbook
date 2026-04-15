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
      attribute :command, Command, collection: true
      attribute :option, Option, collection: true
      attribute :envar, Envar, collection: true
      attribute :varname, Varname, collection: true
      attribute :trademark, Trademark, collection: true
      attribute :email, Email, collection: true
      attribute :uri, Uri, collection: true
      attribute :subscript, Subscript, collection: true
      attribute :superscript, Superscript, collection: true
      attribute :keycap, KeyCap, collection: true
      attribute :application, Application, collection: true
      attribute :phrase, Phrase, collection: true
      attribute :abbrev, Abbrev, collection: true
      attribute :property, Property, collection: true
      attribute :type, Type, collection: true
      attribute :citerefentry, CiterefEntry, collection: true
      attribute :footnote, Footnote, collection: true
      attribute :errorcode, Errorcode, collection: true
      attribute :errortype, Errortype, collection: true
      attribute :exceptionname, Exceptionname, collection: true
      attribute :constant, Constant, collection: true
      attribute :prompt, Prompt, collection: true
      attribute :enumvalue, Enumvalue, collection: true
      attribute :computeroutput, ComputerOutput, collection: true
      attribute :function, Function, collection: true

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
        map_element "command", to: :command
        map_element "option", to: :option
        map_element "envar", to: :envar
        map_element "varname", to: :varname
        map_element "trademark", to: :trademark
        map_element "email", to: :email
        map_element "uri", to: :uri
        map_element "subscript", to: :subscript
        map_element "superscript", to: :superscript
        map_element "keycap", to: :keycap
        map_element "application", to: :application
        map_element "phrase", to: :phrase
        map_element "abbrev", to: :abbrev
        map_element "property", to: :property
        map_element "type", to: :type
        map_element "citerefentry", to: :citerefentry
        map_element "footnote", to: :footnote
        map_element "errorcode", to: :errorcode
        map_element "errortype", to: :errortype
        map_element "exceptionname", to: :exceptionname
        map_element "constant", to: :constant
        map_element "prompt", to: :prompt
        map_element "enumvalue", to: :enumvalue
        map_element "computeroutput", to: :computeroutput
        map_element "function", to: :function
      end
    end
  end
end