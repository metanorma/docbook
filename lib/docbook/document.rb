# frozen_string_literal: true

require "lutaml/model"

module Docbook
  class Document
    ROOT_ELEMENT_MAP = {
      "article" => Elements::Article,
      "book" => Elements::Book,
      "chapter" => Elements::Chapter,
      "appendix" => Elements::Appendix,
      "preface" => Elements::Preface,
      "part" => Elements::Part,
      "section" => Elements::Section,
      "refentry" => Elements::RefEntry,
      "bibliography" => Elements::Bibliography,
      "glossary" => Elements::Glossary,
      "set" => Elements::Set,
      "reference" => Elements::Reference,
      "topic" => Elements::Topic,
      "dedication" => Elements::Dedication,
      "acknowledgements" => Elements::Acknowledgements,
      "colophon" => Elements::Colophon,
      "index" => Elements::Index,
      "toc" => Elements::Toc,
      "sect1" => Elements::Sect1,
      "sect2" => Elements::Sect2,
      "sect3" => Elements::Sect3,
      "sect4" => Elements::Sect4,
      "sect5" => Elements::Sect5,
      "refsection" => Elements::RefSection,
      "refsect1" => Elements::RefSect1,
      "refsect2" => Elements::RefSect2,
      "refsect3" => Elements::RefSect3,
      "setindex" => Elements::SetIndex,
      "para" => Elements::Para,
      "simplesect" => Elements::Simplesect,
    }.freeze

    class << self
      def from_xml(xml_string)
        root_name = extract_root_element(xml_string)
        raise Docbook::Error, "Empty or invalid XML document" unless root_name

        klass = ROOT_ELEMENT_MAP[root_name]
        unless klass
          raise Docbook::Error,
                "Unsupported DocBook root element: #{root_name}"
        end

        klass.from_xml(xml_string)
      end

      def supports?(root_name)
        klass = ROOT_ELEMENT_MAP[root_name]
        !klass.nil?
      end

      def supported_root_elements
        ROOT_ELEMENT_MAP.select { |_, v| v }.keys
      end

      private

      def extract_root_element(xml_string)
        match = xml_string.match(%r{<\s*([a-zA-Z_][\w.-]*)(?:\s|/|>)})
        match&.[](1)
      end
    end
  end
end
