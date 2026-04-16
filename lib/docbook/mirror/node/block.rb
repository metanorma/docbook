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
    end
  end
end
