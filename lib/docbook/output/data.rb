# frozen_string_literal: true

require "lutaml/model"

module Docbook
  module Output
    # Data class for a single block of content within a section.
    # Types: :paragraph, :image, :code, :blockquote, etc.
    class ContentBlock < Lutaml::Model::Serializable
      attribute :type, :string
      attribute :text, :string
      attribute :src, :string
      attribute :alt, :string
      attribute :title, :string
      attribute :language, :string
      attribute :class_name, :string
      attribute :children, ContentBlock, collection: true

      # Override children getter to lazily initialize an empty array
      # This allows using << operator directly on children without nil checks
      def children
        @children ||= []
      end
    end

    # Data class for a section's content (collection of ContentBlocks).
    class SectionContent < Lutaml::Model::Serializable
      attribute :section_id, :string
      attribute :blocks, ContentBlock, collection: true

      def add_block(block)
        @blocks ||= []
        @blocks << block
      end
    end

    # Data class for TOC sections.
    class SectionData < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :title, :string
      attribute :type, :string
      attribute :number, :string
      attribute :children, SectionData, collection: true

      def add_child(child)
        @children ||= []
        @children << child
      end
    end

    # Numbering entry for map structure
    class NumberingEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :value, :string
    end

    # Content entry for map structure
    class ContentEntry < Lutaml::Model::Serializable
      attribute :key, :string
      attribute :value, SectionContent
    end

    # Content data - collection of entries, serialized separately
    class ContentData < Lutaml::Model::Serializable
      attribute :entries, ContentEntry, collection: true
    end

    # ── Computed Data Models ──────────────────────────────────────────

    # TOC: sections tree + computed numbering
    class Toc < Lutaml::Model::Serializable
      attribute :sections, SectionData, collection: true
      attribute :numbering, NumberingEntry, collection: true
    end

    # Single index term entry
    class IndexTerm < Lutaml::Model::Serializable
      attribute :primary, :string
      attribute :secondary, :string
      attribute :tertiary, :string
      attribute :section_id, :string
      attribute :section_title, :string
      attribute :sort_as, :string
      attribute :sees, :string, collection: true
      attribute :see_alsos, :string, collection: true

      def sees
        @sees ||= []
      end

      def see_alsos
        @see_alsos ||= []
      end
    end

    # Group of index terms under a letter
    class IndexGroup < Lutaml::Model::Serializable
      attribute :letter, :string
      attribute :entries, IndexTerm, collection: true

      def entries
        @entries ||= []
      end
    end

    # Computed index data
    class Index < Lutaml::Model::Serializable
      attribute :title, :string
      attribute :type, :string
      attribute :groups, IndexGroup, collection: true

      def groups
        @groups ||= []
      end
    end

    # Top-level output: all computed data for the Vue SPA
    # This is the single model that gets serialized for both single-file and directory modes
    class DocbookOutput < Lutaml::Model::Serializable
      attribute :title, :string
      attribute :toc, Toc
      attribute :content, ContentData
      attribute :index, Index
    end

    # Top-level document data (title only; TOC, content, index are separate)
    class DocumentData < Lutaml::Model::Serializable
      attribute :title, :string
    end

    # OOP Numbering builder with proper scope tracking
    # Handles: Part (Roman), Chapter (Arabic, scoped to part), Section (hierarchical), Appendix (Alpha)
    class NumberingBuilder
      attr_reader :numbering  # returns hash of id => formatted_number_string

      def initialize
        @numbering = {}
        @part_counter = 0
        @chapter_counters = {}  # part_index => chapter_counter
        @appendix_counter = 0
        @section_counters = {}  # chapter_xml_id => [counter_level_1, counter_level_2, ...]
      end

      def next_part
        @part_counter += 1
        roman_numeral(@part_counter)
      end

      def next_chapter(part_index)
        @chapter_counters[part_index] ||= 0
        @chapter_counters[part_index] += 1
        @chapter_counters[part_index].to_s
      end

      def next_section(scope_id)
        # Flat sequential numbering per scope: 1, 2, 3, 4... within each parent section
        @section_counters[scope_id] ||= 0
        @section_counters[scope_id] += 1
        @section_counters[scope_id].to_s
      end

      def next_appendix
        @appendix_counter += 1
        alpha_numeral(@appendix_counter)
      end

      def set_number(id, number)
        @numbering[id] = number
      end

      private

      def roman_numeral(num)
        result = +""
        roman_map = { 1000 => 'M', 900 => 'CM', 500 => 'D', 400 => 'CD', 100 => 'C', 90 => 'XC', 50 => 'L', 40 => 'XL', 10 => 'X', 9 => 'IX', 5 => 'V', 4 => 'IV', 1 => 'I' }
        roman_map.each do |value, letter|
          while num >= value
            result << letter
            num -= value
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
