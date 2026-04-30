# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      autoload :Paragraph, "#{__dir__}/handlers/paragraph"
      autoload :CodeBlock, "#{__dir__}/handlers/code_block"
      autoload :Blockquote, "#{__dir__}/handlers/blockquote"
      autoload :List, "#{__dir__}/handlers/list"
      autoload :Admonition, "#{__dir__}/handlers/admonition"
      autoload :Table, "#{__dir__}/handlers/table"
      autoload :Media, "#{__dir__}/handlers/media"
      autoload :Section, "#{__dir__}/handlers/section"
      autoload :Glossary, "#{__dir__}/handlers/glossary"
      autoload :Bibliography, "#{__dir__}/handlers/bibliography"
      autoload :Index, "#{__dir__}/handlers/index"
      autoload :Procedure, "#{__dir__}/handlers/procedure"
      autoload :Callout, "#{__dir__}/handlers/callout"
      autoload :QandASet, "#{__dir__}/handlers/qandaset"
      autoload :Annotation, "#{__dir__}/handlers/annotation"
      autoload :Footnote, "#{__dir__}/handlers/footnote"
      autoload :Equation, "#{__dir__}/handlers/equation"
      autoload :Sidebar, "#{__dir__}/handlers/sidebar"
      autoload :Inline, "#{__dir__}/handlers/inline"
      autoload :Reference, "#{__dir__}/handlers/reference"
      autoload :Structural, "#{__dir__}/handlers/structural"
      autoload :Example, "#{__dir__}/handlers/example"
    end
  end
end
