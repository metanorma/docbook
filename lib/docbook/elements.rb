# frozen_string_literal: true

module Docbook
  module Elements
    # Concerns (must load before elements that use them)
    autoload :HasNumber, "#{__dir__}/elements/concerns/has_number"

    # Structural elements
    autoload :Article, "#{__dir__}/elements/article"
    autoload :Book, "#{__dir__}/elements/book"
    autoload :Chapter, "#{__dir__}/elements/chapter"
    autoload :Part, "#{__dir__}/elements/part"
    autoload :Section, "#{__dir__}/elements/section"
    autoload :Appendix, "#{__dir__}/elements/appendix"
    autoload :Preface, "#{__dir__}/elements/preface"
    autoload :SetIndex, "#{__dir__}/elements/setindex"
    autoload :RefEntry, "#{__dir__}/elements/refentry"
    autoload :RefSection, "#{__dir__}/elements/refsection"
    autoload :RefSect1, "#{__dir__}/elements/refsect1"
    autoload :RefSect2, "#{__dir__}/elements/refsect2"
    autoload :RefSect3, "#{__dir__}/elements/refsect3"
    autoload :Sect1, "#{__dir__}/elements/sect1"
    autoload :Sect2, "#{__dir__}/elements/sect2"
    autoload :Sect3, "#{__dir__}/elements/sect3"
    autoload :Sect4, "#{__dir__}/elements/sect4"
    autoload :Sect5, "#{__dir__}/elements/sect5"
    autoload :Dedication, "#{__dir__}/elements/dedication"
    autoload :Acknowledgements, "#{__dir__}/elements/acknowledgements"
    autoload :Colophon, "#{__dir__}/elements/colophon"
    autoload :Set, "#{__dir__}/elements/set"
    autoload :Reference, "#{__dir__}/elements/reference"
    autoload :Topic, "#{__dir__}/elements/topic"

    # Metadata elements
    autoload :Info, "#{__dir__}/elements/info"
    autoload :Title, "#{__dir__}/elements/title"
    autoload :Subtitle, "#{__dir__}/elements/subtitle"
    autoload :Author, "#{__dir__}/elements/author"
    autoload :PersonName, "#{__dir__}/elements/personname"
    autoload :FirstName, "#{__dir__}/elements/firstname"
    autoload :Surname, "#{__dir__}/elements/surname"
    autoload :Honorific, "#{__dir__}/elements/honorific"
    autoload :Copyright, "#{__dir__}/elements/copyright"
    autoload :Year, "#{__dir__}/elements/year"
    autoload :Holder, "#{__dir__}/elements/holder"
    autoload :LegalNotice, "#{__dir__}/elements/legalnotice"
    autoload :ReleaseInfo, "#{__dir__}/elements/releaseinfo"
    autoload :PubDate, "#{__dir__}/elements/pubdate"
    autoload :Date, "#{__dir__}/elements/date"
    autoload :ProductName, "#{__dir__}/elements/productname"
    autoload :ProductNumber, "#{__dir__}/elements/productnumber"
    autoload :Version, "#{__dir__}/elements/version"

    # Block elements
    autoload :Para, "#{__dir__}/elements/para"
    autoload :FormalPara, "#{__dir__}/elements/formalpara"
    autoload :Simplesect, "#{__dir__}/elements/simplesect"
    autoload :SimPara, "#{__dir__}/elements/paragraph_like"

    # List elements
    autoload :OrderedList, "#{__dir__}/elements/orderedlist"
    autoload :ItemizedList, "#{__dir__}/elements/itemizedlist"
    autoload :VariableList, "#{__dir__}/elements/variablelist"
    autoload :ListItem, "#{__dir__}/elements/listitem"
    autoload :Varlistentry, "#{__dir__}/elements/varlistentry"
    autoload :Term, "#{__dir__}/elements/term"

    # Link elements
    autoload :Link, "#{__dir__}/elements/link"
    autoload :Xref, "#{__dir__}/elements/xref"
    autoload :Uri, "#{__dir__}/elements/uri"

    # Inline elements
    autoload :Emphasis, "#{__dir__}/elements/emphasis"
    autoload :Property, "#{__dir__}/elements/property"
    autoload :Code, "#{__dir__}/elements/code"
    autoload :Literal, "#{__dir__}/elements/literal"
    autoload :Filename, "#{__dir__}/elements/filename"
    autoload :ClassName, "#{__dir__}/elements/classname"
    autoload :Function, "#{__dir__}/elements/function"
    autoload :Parameter, "#{__dir__}/elements/parameter"
    autoload :Variable, "#{__dir__}/elements/variable"
    autoload :Type, "#{__dir__}/elements/type"
    autoload :Tag, "#{__dir__}/elements/tag"
    autoload :Att, "#{__dir__}/elements/att"
    autoload :Quote, "#{__dir__}/elements/quote"
    autoload :Citation, "#{__dir__}/elements/citation"
    autoload :CiterefEntry, "#{__dir__}/elements/citerefentry"
    autoload :Citetitle, "#{__dir__}/elements/citetitle"
    autoload :Abbrev, "#{__dir__}/elements/abbrev"
    autoload :FirstTerm, "#{__dir__}/elements/firstterm"
    autoload :Glossterm, "#{__dir__}/elements/glossterm"
    autoload :ForeignPhrase, "#{__dir__}/elements/foreignphrase"
    autoload :Phrase, "#{__dir__}/elements/phrase"
    autoload :BuildTarget, "#{__dir__}/elements/buildtarget"
    autoload :Dir, "#{__dir__}/elements/dir"
    autoload :Replaceable, "#{__dir__}/elements/replaceable"
    autoload :Command, "#{__dir__}/elements/command"
    autoload :Option, "#{__dir__}/elements/option"
    autoload :Envar, "#{__dir__}/elements/envar"
    autoload :Varname, "#{__dir__}/elements/varname"
    autoload :Trademark, "#{__dir__}/elements/trademark"
    autoload :Email, "#{__dir__}/elements/email"
    autoload :Subscript, "#{__dir__}/elements/subscript"
    autoload :Superscript, "#{__dir__}/elements/superscript"
    autoload :KeyCap, "#{__dir__}/elements/keycap"
    autoload :Application, "#{__dir__}/elements/application"
    autoload :WordAsWord, "#{__dir__}/elements/wordasword"
    autoload :Errorcode, "#{__dir__}/elements/errorcode"
    autoload :Errortype, "#{__dir__}/elements/errortype"
    autoload :Exceptionname, "#{__dir__}/elements/exceptionname"
    autoload :Constant, "#{__dir__}/elements/constant"
    autoload :Prompt, "#{__dir__}/elements/prompt"
    autoload :Enumvalue, "#{__dir__}/elements/enumvalue"

    # Media elements
    autoload :MediaObject, "#{__dir__}/elements/mediaobject"
    autoload :ImageObject, "#{__dir__}/elements/imageobject"
    autoload :ImageData, "#{__dir__}/elements/imagedata"
    autoload :Alt, "#{__dir__}/elements/alt"
    autoload :Figure, "#{__dir__}/elements/figure"
    autoload :InformalFigure, "#{__dir__}/elements/informalfigure"
    autoload :Inlinemediaobject, "#{__dir__}/elements/inlinemediaobject"
    autoload :ProgramListing, "#{__dir__}/elements/programlisting"
    autoload :Screen, "#{__dir__}/elements/screen"
    autoload :ComputerOutput, "#{__dir__}/elements/computeroutput"
    autoload :UserInput, "#{__dir__}/elements/userinput"
    autoload :TextObject, "#{__dir__}/elements/textobject"
    autoload :AudioObject, "#{__dir__}/elements/audioobject"
    autoload :VideoObject, "#{__dir__}/elements/videoobject"

    # Table elements
    autoload :Table, "#{__dir__}/elements/table"
    autoload :InformalTable, "#{__dir__}/elements/informaltable"
    autoload :TGroup, "#{__dir__}/elements/tgroup"
    autoload :THead, "#{__dir__}/elements/thead"
    autoload :TBody, "#{__dir__}/elements/tbody"
    autoload :TFoot, "#{__dir__}/elements/tfoot"
    autoload :Row, "#{__dir__}/elements/row"
    autoload :Entry, "#{__dir__}/elements/entry"
    autoload :EntryTbl, "#{__dir__}/elements/entrytbl"

    # Admonition elements
    autoload :Note, "#{__dir__}/elements/note"
    autoload :Warning, "#{__dir__}/elements/warning"
    autoload :Caution, "#{__dir__}/elements/caution"
    autoload :Important, "#{__dir__}/elements/important"
    autoload :Tip, "#{__dir__}/elements/tip"
    autoload :Danger, "#{__dir__}/elements/danger"

    # Bibliography elements
    autoload :Bibliography, "#{__dir__}/elements/bibliography"
    autoload :Bibliolist, "#{__dir__}/elements/bibliolist"
    autoload :Bibliomixed, "#{__dir__}/elements/bibliomixed"
    autoload :Biblioref, "#{__dir__}/elements/biblioref"
    autoload :OrgName, "#{__dir__}/elements/orgname"
    autoload :PublisherName, "#{__dir__}/elements/publishername"

    # Glossary elements
    autoload :Glossary, "#{__dir__}/elements/glossary"
    autoload :GlossEntry, "#{__dir__}/elements/glossentry"
    autoload :GlossDef, "#{__dir__}/elements/glossdef"
    autoload :GlossSee, "#{__dir__}/elements/glosssee"
    autoload :GlossSeeAlso, "#{__dir__}/elements/glossseealso"

    # Index elements
    autoload :Index, "#{__dir__}/elements/index"
    autoload :IndexTerm, "#{__dir__}/elements/indexterm"
    autoload :IndexDiv, "#{__dir__}/elements/indexdiv"
    autoload :IndexEntry, "#{__dir__}/elements/indexentry"
    autoload :Primary, "#{__dir__}/elements/primary"
    autoload :Secondary, "#{__dir__}/elements/secondary"
    autoload :Tertiary, "#{__dir__}/elements/tertiary"
    autoload :See, "#{__dir__}/elements/see"
    autoload :SeeAlso, "#{__dir__}/elements/seealso"

    # TOC elements
    autoload :Toc, "#{__dir__}/elements/toc"
    autoload :TocDiv, "#{__dir__}/elements/tocdiv"
    autoload :TocEntry, "#{__dir__}/elements/tocentry"

    # Footnote elements
    autoload :Footnote, "#{__dir__}/elements/footnote"
    autoload :FootnoteRef, "#{__dir__}/elements/footnoteref"

    # Callout elements
    autoload :Callout, "#{__dir__}/elements/callout"
    autoload :CalloutList, "#{__dir__}/elements/calloutlist"
    autoload :Co, "#{__dir__}/elements/co"

    # Example / Equation elements
    autoload :Example, "#{__dir__}/elements/example"
    autoload :InformalExample, "#{__dir__}/elements/informalexample"
    autoload :Equation, "#{__dir__}/elements/equation"

    # Procedure elements
    autoload :Procedure, "#{__dir__}/elements/procedure"
    autoload :Step, "#{__dir__}/elements/step"
    autoload :SubSteps, "#{__dir__}/elements/substeps"

    # QandA elements
    autoload :QandASet, "#{__dir__}/elements/qandaset"
    autoload :QandAEntry, "#{__dir__}/elements/qandaentry"
    autoload :Question, "#{__dir__}/elements/question"
    autoload :Answer, "#{__dir__}/elements/answer"

    # Sidebar
    autoload :SideBar, "#{__dir__}/elements/sidebar"

    # Remark
    autoload :Remark, "#{__dir__}/elements/remark"

    # Other elements
    autoload :BlockQuote, "#{__dir__}/elements/blockquote"
    autoload :Quotation, "#{__dir__}/elements/quotation"
    autoload :Attribution, "#{__dir__}/elements/attribution"
    autoload :MsgSet, "#{__dir__}/elements/msgset"
    autoload :Msg, "#{__dir__}/elements/msg"
    autoload :Msgexplan, "#{__dir__}/elements/msgexplan"
    autoload :LiteralLayout, "#{__dir__}/elements/literallayout"
    autoload :Address, "#{__dir__}/elements/address"
    autoload :Annotation, "#{__dir__}/elements/annotation"

    # RefEntry elements
    autoload :RefMeta, "#{__dir__}/elements/refmeta"
    autoload :RefNamediv, "#{__dir__}/elements/refnamediv"
    autoload :RefPurpose, "#{__dir__}/elements/refpurpose"
    autoload :RefName, "#{__dir__}/elements/refname"
    autoload :RefEntryTitle, "#{__dir__}/elements/refentrytitle"
    autoload :RefMiscInfo, "#{__dir__}/elements/refmiscinfo"
    autoload :FieldSynopsis, "#{__dir__}/elements/fieldsynopsis"
    autoload :Initializer, "#{__dir__}/elements/initializer"
  end
end
