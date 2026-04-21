# frozen_string_literal: true

module Docbook
  # Resolves xrefs in a DocBook document by building an O(1) xml:id lookup hash
  # and resolving all xref/linkend references to their target titles.
  # Resolves xrefs in a DocBook document by building an O(1) xml:id lookup hash
  # and resolving all xref/linkend references to their target titles.
  #
  # @example
  #   resolver = Docbook::XrefResolver.new(parsed_doc)
  #   resolver.resolve!
  #   resolver.title_for("intro")  # => "Introduction"
  class XrefResolver
    # @param document [Docbook::Elements::Book, Docbook::Elements::Article, etc.] parsed document
    def initialize(document)
      @document = document
      @xml_id_map = {}
    end

    # Build the xml:id to element lookup hash.
    # @return [self]
    def resolve!
      @xml_id_map = build_xml_id_map(@document)
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

    def build_xml_id_map(el, map = {})
      return map unless el.is_a?(Lutaml::Model::Serializable)

      map[el.xml_id.to_s] = el if el.xml_id

      # Walk via each_mixed_content to catch ALL element types
      if el.respond_to?(:each_mixed_content)
        el.each_mixed_content do |node|
          next if node.is_a?(String)

          build_xml_id_map(node, map)
        end
      end

      map
    end

    def best_title(el)
      case el
      when Docbook::Elements::Article, Docbook::Elements::Book
        info_title = el.info&.title
        info_title&.content&.join
      when Docbook::Elements::Section, Docbook::Elements::Chapter, Docbook::Elements::Appendix,
           Docbook::Elements::Preface, Docbook::Elements::Part, Docbook::Elements::Reference
        el.title&.content&.join
      when Docbook::Elements::Figure, Docbook::Elements::InformalFigure
        el.title&.content&.join
      when Docbook::Elements::Example, Docbook::Elements::InformalExample
        el.title&.content&.join
      when Docbook::Elements::Table, Docbook::Elements::InformalTable
        el.title&.content&.join
      when Docbook::Elements::Procedure
        el.title&.content&.join
      when Docbook::Elements::Equation
        el.title&.content&.join
      when Docbook::Elements::GlossEntry
        el.glossterm&.content&.join if el.respond_to?(:glossterm)
      when Docbook::Elements::Bibliomixed
        el.abbrev&.content&.join ||
          begin
            ct = el.citetitle&.first
            ct&.content&.join
          end ||
          format_bibliomixed_id(el.xml_id)
      when Docbook::Elements::RefEntry
        resolve_refentry_title(el)
      else
        begin
          el.title&.content&.join
        rescue StandardError
          nil
        end
      end
    end

    def resolve_refentry_title(refentry)
      if refentry.respond_to?(:refmeta) && refentry.refmeta
        title = refentry.refmeta.refentrytitle
        vol = refentry.refmeta.manvolnum
        if title && vol
          "#{title}(#{vol})"
        elsif title
          title
        end
      end
    end

    # Format xml:id into a readable title for bibliography entries
    # e.g., "rfc2119" -> "RFC 2119", "iso8879" -> "ISO 8879"
    def format_bibliomixed_id(xml_id)
      return nil unless xml_id

      id = xml_id.to_s
      # Handle known prefixes
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

      # Clean up suffix: strip leading/trailing whitespace and hyphens
      suffix = suffix.strip.gsub(/\A-+/, "").delete_suffix("-")
      return nil if suffix.empty?

      # Apply formatting
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
