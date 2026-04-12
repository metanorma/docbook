# frozen_string_literal: true

module Docbook
  module Services
    # Pre-computes section numbering for the document
    # Handles: Roman numerals for Parts, Arabic for Chapters,
    #          Hierarchical for Sections, Alpha for Appendices
    class NumberingService
      def initialize(document)
        @document = document
        @numbering = []
        @part_counter = 0
        @chapter_counters = {}  # part_index => counter
        @appendix_counter = 0
        @section_counters = {}  # scope_id => [level1, level2, ...]
      end

      def generate
        @numbering = []
        @part_counter = 0
        @chapter_counters = {}
        @appendix_counter = 0
        @section_counters = {}

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

        # Reset section counters for this chapter
        scope_id = chapter.xml_id || "chapter-#{chapter_number}"
        @section_counters[scope_id] = [0, 0, 0, 0, 0]

        process_children(chapter, parent_info.merge(chapter_scope: scope_id))
      end

      def process_appendix(appendix, parent_info)
        @appendix_counter += 1
        appendix_number = alpha_numeral(@appendix_counter)

        add_numbering(appendix, appendix_number, "appendix")

        # Reset section counters for this appendix
        scope_id = appendix.xml_id || "appendix-#{appendix_number}"
        @section_counters[scope_id] = [0, 0, 0, 0, 0]

        process_children(appendix, parent_info.merge(appendix_scope: scope_id))
      end

      def process_section(section, parent_info)
        # Determine scope
        scope_id = parent_info[:chapter_scope] ||
                    parent_info[:appendix_scope] ||
                    section.xml_id ||
                    "section-#{@numbering.length}"

        # Initialize counters for this scope
        @section_counters[scope_id] ||= [0, 0, 0, 0, 0]

        # Count nesting depth
        depth = section_depth(section)

        # Increment counter at this depth
        @section_counters[scope_id][depth - 1] += 1

        # Reset counters for deeper levels
        (depth...5).each { |i| @section_counters[scope_id][i] = 0 }

        # Build number string
        numbers = @section_counters[scope_id].first(depth)
        section_number = numbers.join(".")

        add_numbering(section, section_number, "section")

        process_children(section, parent_info)
      end

      def process_refentry(refentry, parent_info)
        refname = if refentry.refnamediv&.refname
          refentry.refnamediv.refname.map(&:content).join(" ")
        elsif refentry.refmeta&.refentrytitle
          refentry.refmeta.refentrytitle.content
        else
          refentry.xml_id || "refentry"
        end

        add_numbering(refentry, refname, "refentry")
      end

      def process_children(element, parent_info)
        return unless element.respond_to?(:elements)

        Array(element.elements).each do |child|
          process_document(child, parent_info)
        end
      end

      def section_depth(section)
        # Determine section nesting depth
        depth = 1
        el = section
        while el.respond_to?(:parent) && el.parent
          depth += 1
          el = el.parent
        end
        [depth, 5].min
      end

      def add_numbering(element, number, type)
        @numbering << Models::SectionNumber.new(
          id: element.xml_id || "element-#{@numbering.length}",
          number: number.to_s,
          type: type
        )
      end

      def roman_numeral(num)
        result = +""
        roman_map = {
          1000 => 'M', 900 => 'CM', 500 => 'D', 400 => 'CD',
          100 => 'C', 90 => 'XC', 50 => 'L', 40 => 'XL',
          10 => 'X', 9 => 'IX', 5 => 'V', 4 => 'IV', 1 => 'I'
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
        while num > 0
          num -= 1
          result = (('A'.ord + (num % 26)).chr) + result
          num /= 26
        end
        result
      end
    end
  end
end
