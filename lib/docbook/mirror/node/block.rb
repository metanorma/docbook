# frozen_string_literal: true

require_relative "base"

module Docbook
  module Mirror
    class Node
      class Paragraph < Base
        PM_TYPE = "paragraph"
      end

      class Document < Base
        PM_TYPE = "doc"
      end

      class Heading < Base
        PM_TYPE = "heading"
      end

      class CodeBlock < Base
        PM_TYPE = "code_block"
      end

      class Blockquote < Base
        PM_TYPE = "blockquote"
      end

      class BulletList < Base
        PM_TYPE = "bullet_list"
      end

      class OrderedList < Base
        PM_TYPE = "ordered_list"
      end

      class ListItem < Base
        PM_TYPE = "list_item"
      end

      class DefinitionList < Base
        PM_TYPE = "dl"
      end

      class DefinitionTerm < Base
        PM_TYPE = "definition_term"
      end

      class DefinitionDescription < Base
        PM_TYPE = "definition_description"
      end

      class Image < Base
        PM_TYPE = "image"
      end

      class Admonition < Base
        PM_TYPE = "admonition"
      end

      class Table < Base
        PM_TYPE = "table"
      end

      class TableHead < Base
        PM_TYPE = "table_head"
      end

      class TableBody < Base
        PM_TYPE = "table_body"
      end

      class TableRow < Base
        PM_TYPE = "table_row"
      end

      class TableCell < Base
        PM_TYPE = "table_cell"
      end

      class Section < Base
        PM_TYPE = "section"
      end

      class Chapter < Base
        PM_TYPE = "chapter"
      end

      class Appendix < Base
        PM_TYPE = "appendix"
      end

      class Part < Base
        PM_TYPE = "part"
      end

      class Reference < Base
        PM_TYPE = "reference"
      end

      class RefEntry < Base
        PM_TYPE = "refentry"
      end

      class RefSection < Base
        PM_TYPE = "refsection"
      end

      # Frontmatter / Backmatter
      class Preface < Base
        PM_TYPE = "preface"
      end

      class Dedication < Base
        PM_TYPE = "dedication"
      end

      class Acknowledgements < Base
        PM_TYPE = "acknowledgements"
      end

      class Colophon < Base
        PM_TYPE = "colophon"
      end

      # Glossary
      class Glossary < Base
        PM_TYPE = "glossary"
      end

      class GlossEntry < Base
        PM_TYPE = "gloss_entry"
      end

      class GlossTerm < Base
        PM_TYPE = "gloss_term"
      end

      class GlossDef < Base
        PM_TYPE = "gloss_def"
      end

      class GlossSee < Base
        PM_TYPE = "gloss_see"
      end

      class GlossSeeAlso < Base
        PM_TYPE = "gloss_see_also"
      end

      # Bibliography
      class Bibliography < Base
        PM_TYPE = "bibliography"
      end

      class BiblioEntry < Base
        PM_TYPE = "biblio_entry"
      end

      # Index
      class IndexBlock < Base
        PM_TYPE = "index_block"
      end

      class IndexDiv < Base
        PM_TYPE = "index_div"
      end

      class IndexEntry < Base
        PM_TYPE = "index_entry"
      end

      # Content blocks
      class Procedure < Base
        PM_TYPE = "procedure"
      end

      class Step < Base
        PM_TYPE = "step"
      end

      class SubSteps < Base
        PM_TYPE = "substeps"
      end

      class Equation < Base
        PM_TYPE = "equation"
      end

      class CalloutList < Base
        PM_TYPE = "calloutlist"
      end

      class Callout < Base
        PM_TYPE = "callout"
      end

      class Sidebar < Base
        PM_TYPE = "sidebar"
      end

      class SimPara < Base
        PM_TYPE = "simpara"
      end

      # Structural
      class Set < Base
        PM_TYPE = "set"
      end

      class Article < Base
        PM_TYPE = "article"
      end

      class Topic < Base
        PM_TYPE = "topic"
      end

      # Footnotes
      class Footnotes < Base
        PM_TYPE = "footnotes"
      end

      class FootnoteMarker < Base
        PM_TYPE = "footnote_marker"
      end

      class FootnoteEntry < Base
        PM_TYPE = "footnote_entry"
      end

      # Caption
      class Caption < Base
        PM_TYPE = "caption"
      end

      # Figure (formal, with title)
      class Figure < Base
        PM_TYPE = "figure"
      end
    end
  end
end
