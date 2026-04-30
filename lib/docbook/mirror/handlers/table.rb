# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Table
        def self.call(element, context:)
          attrs = {}
          attrs[:xml_id] = element.xml_id if element.respond_to?(:xml_id) && element.xml_id
          if element.respond_to?(:title) && element.title
            attrs[:title] = element.title.content.join
          end
          attrs[:frame] = element.frame if element.respond_to?(:frame) && element.frame
          attrs[:colsep] = element.colsep if element.respond_to?(:colsep) && element.colsep
          attrs[:rowsep] = element.rowsep if element.respond_to?(:rowsep) && element.rowsep

          table_content = []

          tgroups = element.respond_to?(:tgroup) ? element.tgroup : []
          tgroups.each do |tg|
            attrs[:cols] = tg.cols if tg.respond_to?(:cols) && tg.cols

            if tg.respond_to?(:thead) && tg.thead
              head_rows = build_table_rows(tg.thead.row)
              table_content << Node::TableHead.new(content: head_rows) unless head_rows.empty?
            end

            next unless tg.respond_to?(:tbody) && tg.tbody

            body_rows = build_table_rows(tg.tbody.row)
            table_content << Node::TableBody.new(content: body_rows) unless body_rows.empty?
          end

          Node::Table.new(attrs: attrs.compact,
                          content: table_content)
        end

        def self.build_table_rows(rows)
          rows.map do |row|
            cells = row.entry.map do |entry|
              cell_content = []
              text = entry.content.join.strip
              cell_content << Node::Text.new(text: text) unless text.empty?
              cell_attrs = {}
              cell_attrs[:align] = entry.align if entry.align
              cell_attrs[:valign] = entry.valign if entry.valign
              cell_attrs[:namest] = entry.namest if entry.namest
              cell_attrs[:nameend] = entry.nameend if entry.nameend
              cell_attrs[:morerows] = entry.morerows if entry.morerows
              Node::TableCell.new(attrs: cell_attrs.compact,
                                  content: cell_content)
            end
            Node::TableRow.new(content: cells)
          end
        end
      end
    end
  end
end
