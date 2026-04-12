# frozen_string_literal: true

module Docbook
  # Resolves xrefs in a DocBook document by building an O(1) xml:id lookup hash
  # and resolving all xref/linkend references to their target titles.
  class XrefResolver
    def initialize(document)
      @document = document
      @xml_id_map = {}
    end

    # Build the xml:id -> element hash
    def resolve!
      @xml_id_map = build_xml_id_map(@document)
      self
    end

    # Get the resolved title text for a linkend ID
    def title_for(linkend)
      target = @xml_id_map[linkend.to_s]
      return nil unless target
      best_title(target)
    end

    # Get element by xml:id
    def [](xml_id)
      @xml_id_map[xml_id.to_s]
    end

    private

    def build_xml_id_map(el, map = {})
      return map unless el.is_a?(Lutaml::Model::Serializable)

      map[el.xml_id.to_s] = el if el.xml_id

      # Walk child collections based on element type
      case el
      when Docbook::Elements::Book
        el.part&.each { |p| build_xml_id_map(p, map) }
        el.chapter&.each { |c| build_xml_id_map(c, map) }
        el.appendix&.each { |a| build_xml_id_map(a, map) }
        el.preface&.each { |p| build_xml_id_map(p, map) }
        el.glossary&.each { |g| build_xml_id_map(g, map) }
        el.bibliography&.each { |b| build_xml_id_map(b, map) }
        el.index&.each { |i| build_xml_id_map(i, map) }
      when Docbook::Elements::Article
        el.section&.each { |s| build_xml_id_map(s, map) }
      when Docbook::Elements::Part
        el.chapter&.each { |c| build_xml_id_map(c, map) }
        el.appendix&.each { |a| build_xml_id_map(a, map) }
        el.reference&.each { |r| build_xml_id_map(r, map) }
        el.glossary&.each { |g| build_xml_id_map(g, map) }
        el.bibliography&.each { |b| build_xml_id_map(b, map) }
        el.index&.each { |i| build_xml_id_map(i, map) }
      when Docbook::Elements::Chapter, Docbook::Elements::Appendix,
           Docbook::Elements::Section, Docbook::Elements::Preface
        el.section&.each { |s| build_xml_id_map(s, map) }
        el.bibliolist&.each { |bl| build_xml_id_map(bl, map) }
      when Docbook::Elements::Reference
        el.refentry&.each { |r| build_xml_id_map(r, map) }
      when Docbook::Elements::Bibliolist
        el.bibliomixed&.each { |b| build_xml_id_map(b, map) }
      when Docbook::Elements::Bibliography
        el.bibliomixed&.each { |b| build_xml_id_map(b, map) }
        if el.respond_to?(:bibliolist)
          el.bibliolist&.each { |bl| build_xml_id_map(bl, map) }
        end
      end

      map
    end

    def best_title(el)
      case el
      when Docbook::Elements::Article, Docbook::Elements::Book
        el.info&.title&.content
      when Docbook::Elements::Section, Docbook::Elements::Chapter, Docbook::Elements::Appendix,
           Docbook::Elements::Preface, Docbook::Elements::Part, Docbook::Elements::Reference
        el.title&.content
      when Docbook::Elements::Bibliomixed
        el.abbrev&.content || el.citetitle&.first&.content
      else
        el.title&.content rescue nil
      end
    end
  end
end
