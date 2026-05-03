# frozen_string_literal: true

module Docbook
  module Services
    class NumberingService
      SCOPED_COUNTER_ROLES = %i[figure example table].freeze

      ROLE_HANDLERS = {
        part: :process_part,
        chapter: :process_chapter,
        appendix: :process_appendix,
        section: :process_section,
      }.freeze

      def initialize(document)
        @document = document
        @numbering = []
        @part_counter = 0
        @chapter_counters = {}
        @appendix_counter = 0
        @section_counters = {}
        @scoped_counters = { figure: {}, example: {}, table: {} }
      end

      def generate
        @numbering = []
        @part_counter = 0
        @chapter_counters = {}
        @appendix_counter = 0
        @section_counters = {}
        @scoped_counters = { figure: {}, example: {}, table: {} }

        process(@document)
        @numbering
      end

      private

      def process(element, parent_info = {})
        return unless element

        role = element.numbering_role

        if SCOPED_COUNTER_ROLES.include?(role)
          process_scoped_counter(element, parent_info, role)
        elsif role
          handler = ROLE_HANDLERS[role]
          send(handler, element, parent_info) if handler
        else
          process_children(element, parent_info)
        end
      end

      def process_part(part, parent_info)
        @part_counter += 1
        part_number = roman_numeral(@part_counter)

        add_numbering(part, part_number, "part")

        @chapter_counters[@part_counter] = 0

        process_children(part, parent_info.merge(part_counter: @part_counter))
      end

      def process_chapter(chapter, parent_info)
        part_idx = parent_info[:part_counter] || 0
        @chapter_counters[part_idx] ||= 0
        @chapter_counters[part_idx] += 1
        chapter_number = @chapter_counters[part_idx].to_s

        add_numbering(chapter, chapter_number, "chapter")

        scope_id = chapter.element_id
        @section_counters[scope_id] = [0, 0, 0, 0, 0]
        SCOPED_COUNTER_ROLES.each { |r| @scoped_counters[r][scope_id] = 0 }

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

        scope_id = appendix.element_id
        @section_counters[scope_id] = [0, 0, 0, 0, 0]
        SCOPED_COUNTER_ROLES.each { |r| @scoped_counters[r][scope_id] = 0 }

        process_children(appendix, parent_info.merge(
                                     appendix_scope: scope_id,
                                     section_depth: 1,
                                     appendix_number: appendix_number,
                                   ))
      end

      def process_section(section, parent_info)
        scope_id = parent_info[:chapter_scope] ||
          parent_info[:appendix_scope] ||
          section.element_id

        @section_counters[scope_id] ||= [0, 0, 0, 0, 0]

        depth = parent_info[:section_depth] || 1

        @section_counters[scope_id][depth - 1] += 1

        (depth...5).each { |i| @section_counters[scope_id][i] = 0 }

        numbers = @section_counters[scope_id].first(depth)
        section_number = numbers.join(".")

        add_numbering(section, section_number, "section")

        process_children(section, parent_info.merge(section_depth: depth + 1))
      end

      def process_scoped_counter(element, parent_info, role)
        scope_id = parent_info[:chapter_scope] || parent_info[:appendix_scope]
        return unless scope_id

        counters = @scoped_counters[role]
        counters[scope_id] ||= 0
        counters[scope_id] += 1
        num = counters[scope_id]

        prefix = parent_info[:chapter_number] || parent_info[:appendix_number]
        number = prefix ? "#{prefix}.#{num}" : num.to_s

        add_numbering(element, number, role.to_s)

        process_children(element, parent_info)
      end

      def process_children(element, parent_info)
        element.walk_children { |child| process(child, parent_info) }
      end

      def add_numbering(element, number, type)
        id = element.element_id
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
