# frozen_string_literal: true

module Docbook
  # Resolves xrefs in a DocBook document by building an O(1) xml:id lookup hash
  # and resolving all xref/linkend references to their target titles.
  #
  # @example
  #   resolver = Docbook::XrefResolver.new(parsed_doc)
  #   resolver.resolve!
  #   resolver.title_for("intro")  # => "Introduction"
  class XrefResolver
    def initialize(document)
      @document = document
      @xml_id_map = {}
    end

    # Build the xml:id to element lookup hash.
    # @return [self]
    def resolve!
      @xml_id_map = {}
      build_xml_id_map(@document)
      self
    end

    # Get the resolved title text for a linkend ID.
    # @param linkend [String] the xml:id to look up
    # @return [String, nil]
    def title_for(linkend)
      target = @xml_id_map[linkend.to_s]
      return nil unless target

      best_title(target)
    end

    # Get element by xml:id.
    # @param xml_id [String]
    # @return [Docbook::Elements::*, nil]
    def [](xml_id)
      @xml_id_map[xml_id.to_s]
    end

    private

    def build_xml_id_map(el)
      @xml_id_map[el.xml_id.to_s] = el if el.xml_id

      el.walk_children { |child| build_xml_id_map(child) }
    end

    def best_title(el)
      el.resolve_title || format_bibliomixed_id(el.xml_id)
    end

    # Format xml:id into a readable title for bibliography entries
    def format_bibliomixed_id(xml_id)
      return nil unless xml_id

      id = xml_id.to_s
      suffix = if id.start_with?("rfc") && id.length > 3
                 id[3..]
               elsif id.start_with?("iso") && id.length > 3
                 id[3..]
               elsif id.start_with?("xml") && id.length > 3
                 id[3..]
               elsif id.start_with?("bib.")
                 id[4..]
               else
                 id
               end

      return nil if suffix.nil? || suffix.empty?

      suffix = suffix.strip.gsub(/\A-+/, "").delete_suffix("-")
      return nil if suffix.empty?

      if id.start_with?("rfc")
        "RFC #{suffix}"
      elsif id.start_with?("iso")
        "ISO #{suffix.gsub("-", " ")}"
      elsif id.start_with?("xml")
        "XML #{suffix.gsub("-", " ")}"
      elsif id.start_with?("bib.")
        suffix.capitalize
      else
        suffix.split("-").map(&:capitalize).join(" ")
      end
    end
  end
end
