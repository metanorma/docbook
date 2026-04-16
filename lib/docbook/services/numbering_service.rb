# frozen_string_literal: true

module Docbook
  module Services
    # Pre-computes section numbering for the document
    # Handles: Roman numerals for Parts, Arabic for Chapters,
    #          Hierarchical for Sections, Alpha for Appendices
    #          Auto-numbering for Figures, Examples, Tables
    class NumberingService
      include ElementIdHelper

      def initialize(document)
        @document = document
        @numbering = []
        @part_counter = 0
        @chapter_counters = {}  # part_index => counter
        @appendix_counter = 0
        @section_counters = {}  # scope_id => [level1, level2, ...]
        @figure_counters = {}   # scope_id => counter
        @example_counters = {}  # scope_id => counter
        @table_counters = {}    # scope_id => counter
      end

      def generate
        @numbering = []
        @part_counter = 0
        @chapter_counters = {}
        @appendix_counter = 0
        @section_counters = {}
        @figure_counters = {}
        @example_counters = {}
        @table_counters = {}

        process_document(@document)
        @numbering
      end

      private

      def process_document(element, parent_info = {})
        return unless element

        case element
        when Elements::Part
          process_part(element, parent_info)
        when Elements::Chapter
          process_chapter(element, parent_info)
        when Elements::Appendix
          process_appendix(element, parent_info)
        when Elements::Section
          process_section(element, parent_info)
        when Elements::RefEntry
          process_refentry(element, parent_info)
        when Elements::Figure, Elements::InformalFigure
          process_figure(element, parent_info)
        when Elements::Example, Elements::InformalExample
          process_example(element, parent_info)
        when Elements::Table
          process_table(element, parent_info)
        else
          # Process children
          process_children(element, parent_info)
        end
      end

      def process_part(part, parent_info)
        @part_counter += 1
        part_number = roman_numeral(@part_counter)

        add_numbering(part, part_number, "part")

        # Track chapters within this part
        @chapter_counters[@part_counter] = 0

        process_children(part, parent_info.merge(part_counter: @part_counter))
      end

      def process_chapter(chapter, parent_info)
        part_idx = parent_info[:part_counter] || 0
        @chapter_counters[part_idx] ||= 0
        @chapter_counters[part_idx] += 1
        chapter_number = @chapter_counters[part_idx].to_s

        add_numbering(chapter, chapter_number, "chapter")

        # Reset counters for this chapter
        scope_id = element_id(chapter)
        @section_counters[scope_id] = [0, 0, 0, 0, 0]
        @figure_counters[scope_id] = 0
        @example_counters[scope_id] = 0
        @table_counters[scope_id] = 0

        process_children(chapter, parent_info.merge(
                                    chapter_scope: scope_id,
                                    section_depth: 1,
                                    chapter_number: chapter_number,
                                  ))
      end

      def process_appendix(appendix, parent_info)
        @appendix_counter += 1
        appendix_number = alpha_numeral(@appendix_counter)

        add_numbering(appendix, appendix_number, "appendix")

        # Reset counters for this appendix
        scope_id = element_id(appendix)
        @section_counters[scope_id] = [0, 0, 0, 0, 0]
        @figure_counters[scope_id] = 0
        @example_counters[scope_id] = 0
        @table_counters[scope_id] = 0

        process_children(appendix, parent_info.merge(
                                     appendix_scope: scope_id,
                                     section_depth: 1,
                                     appendix_number: appendix_number,
                                   ))
      end

      def process_section(section, parent_info)
        # Determine scope
        scope_id = parent_info[:chapter_scope] ||
          parent_info[:appendix_scope] ||
          element_id(section)

        # Initialize counters for this scope
        @section_counters[scope_id] ||= [0, 0, 0, 0, 0]

        # Depth is tracked via parent_info, default to 1
        depth = parent_info[:section_depth] || 1

        # Increment counter at this depth
        @section_counters[scope_id][depth - 1] += 1

        # Reset counters for deeper levels
        (depth...5).each { |i| @section_counters[scope_id][i] = 0 }

        # Build number string
        numbers = @section_counters[scope_id].first(depth)
        section_number = numbers.join(".")

        add_numbering(section, section_number, "section")

        process_children(section, parent_info.merge(section_depth: depth + 1))
      end

      def process_refentry(refentry, parent_info)
        process_children(refentry, parent_info)
      end

      def process_figure(figure, parent_info)
        scope_id = parent_info[:chapter_scope] || parent_info[:appendix_scope]
        return unless scope_id

        @figure_counters[scope_id] ||= 0
        @figure_counters[scope_id] += 1
        fig_num = @figure_counters[scope_id]

        prefix = parent_info[:chapter_number] || parent_info[:appendix_number]
        number = prefix ? "#{prefix}.#{fig_num}" : fig_num.to_s

        add_numbering(figure, number, "figure")

        process_children(figure, parent_info)
      end

      def process_example(example, parent_info)
        scope_id = parent_info[:chapter_scope] || parent_info[:appendix_scope]
        return unless scope_id

        @example_counters[scope_id] ||= 0
        @example_counters[scope_id] += 1
        ex_num = @example_counters[scope_id]

        prefix = parent_info[:chapter_number] || parent_info[:appendix_number]
        number = prefix ? "#{prefix}.#{ex_num}" : ex_num.to_s

        add_numbering(example, number, "example")

        process_children(example, parent_info)
      end

      def process_table(table, parent_info)
        scope_id = parent_info[:chapter_scope] || parent_info[:appendix_scope]
        return unless scope_id

        @table_counters[scope_id] ||= 0
        @table_counters[scope_id] += 1
        tbl_num = @table_counters[scope_id]

        prefix = parent_info[:chapter_number] || parent_info[:appendix_number]
        number = prefix ? "#{prefix}.#{tbl_num}" : tbl_num.to_s

        add_numbering(table, number, "table")

        process_children(table, parent_info)
      end

      def process_children(element, parent_info)
        # Collect all child elements that need processing
        children = all_child_elements(element)

        children.each do |child|
          process_document(child, parent_info)
        end
      end

      def all_child_elements(element)
        result = []
        return result unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          next if node.is_a?(String)

          result << node
        end
        result
      end

      def add_numbering(element, number, type)
        id = element_id(element)
        @numbering << Models::SectionNumber.new(
          id: id,
          number: number.to_s,
          type: type,
        )
      end

      def roman_numeral(num)
        result = +""
        roman_map = {
          1000 => "M", 900 => "CM", 500 => "D", 400 => "CD",
          100 => "C", 90 => "XC", 50 => "L", 40 => "XL",
          10 => "X", 9 => "IX", 5 => "V", 4 => "IV", 1 => "I"
        }
        remaining = num
        roman_map.each do |value, letter|
          while remaining >= value
            result << letter
            remaining -= value
          end
        end
        result
      end

      def alpha_numeral(num)
        result = ""
        while num.positive?
          num -= 1
          result = ("A".ord + (num % 26)).chr + result
          num /= 26
        end
        result
      end
    end
  end
end
