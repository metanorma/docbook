# frozen_string_literal: true

module Docbook
  module Services
    class DocumentStats
      def initialize(document)
        @document = document
      end

      def generate
        counts = {
          "sections" => 0,
          "images" => 0,
          "code_blocks" => 0,
          "tables" => 0,
          "index_terms" => 0,
          "bibliography_entries" => 0,
          "xincludes" => 0,
        }

        walk(@document, counts)

        {
          "title" => extract_title,
          "subtitle" => extract_subtitle,
          "author" => extract_author,
          "pubdate" => extract_pubdate,
          "releaseinfo" => extract_releaseinfo,
          "copyright" => extract_copyright,
          "root_element" => root_element_name,
          **counts,
        }
      end

      private

      # Map element classes to the counter keys they increment
      COUNTERS = {
        Elements::Section => "sections",
        Elements::Sect1 => "sections",
        Elements::Sect2 => "sections",
        Elements::Sect3 => "sections",
        Elements::Sect4 => "sections",
        Elements::Sect5 => "sections",
        Elements::Chapter => "sections",
        Elements::Part => "sections",
        Elements::Appendix => "sections",
        Elements::Preface => "sections",
        Elements::Reference => "sections",
        Elements::RefEntry => "sections",
        Elements::RefSection => "sections",
        Elements::RefSect1 => "sections",
        Elements::RefSect2 => "sections",
        Elements::RefSect3 => "sections",
        Elements::Simplesect => "sections",
        Elements::Figure => "images",
        Elements::InformalFigure => "images",
        Elements::MediaObject => "images",
        Elements::ProgramListing => "code_blocks",
        Elements::Screen => "code_blocks",
        Elements::LiteralLayout => "code_blocks",
        Elements::Table => "tables",
        Elements::InformalTable => "tables",
        Elements::IndexTerm => "index_terms",
        Elements::Bibliomixed => "bibliography_entries",
      }.freeze

      def walk(node, counts)
        COUNTERS.each do |klass, key|
          if node.is_a?(klass)
            counts[key] += 1
            break
          end
        end

        # Walk all model-defined attributes for child elements
        return unless node.class.respond_to?(:attributes)

        node.class.attributes.each_value do |attr_def|
          value = node.send(attr_def.name)
          next if value.nil?

          case value
          when Array
            value.each { |v| walk(v, counts) if walkable?(v) }
          else
            walk(value, counts) if walkable?(value)
          end
        end
      end

      def walkable?(value)
        value.is_a?(Lutaml::Model::Serializable)
      end

      def extract_title
        info = @document.info if @document.respond_to?(:info)
        if info&.title
          text = text_content(info.title.content)
          return text if text
        end

        title_obj = @document.title if @document.respond_to?(:title)
        text_content(title_obj&.content)
      end

      def extract_author
        info = @document.info if @document.respond_to?(:info)
        authors = info&.author
        return unless authors && !authors.empty?

        authors.filter_map do |a|
          text = text_content(a.content)
          next text if text

          pn = a.personname
          text = text_content(pn&.content)
          next text if text

          parts = []
          parts << text_content(pn.firstname&.content) if pn&.firstname
          parts << text_content(pn.surname&.content) if pn&.surname
          parts.compact!
          parts.any? ? parts.join(" ") : nil
        end.join(", ")
      end

      def extract_subtitle
        info = @document.info if @document.respond_to?(:info)
        text_content(info&.subtitle&.content)
      end

      def extract_pubdate
        info = @document.info if @document.respond_to?(:info)
        text_content(info&.pubdate&.content)
      end

      def extract_releaseinfo
        info = @document.info if @document.respond_to?(:info)
        text_content(info&.releaseinfo&.content)
      end

      def extract_copyright
        info = @document.info if @document.respond_to?(:info)
        copyrights = info&.copyright
        return unless copyrights && !copyrights.empty?

        copyrights.filter_map do |cr|
          years = Array(cr.year).filter_map { |y| text_content(y.content) }.join(", ")
          holders = Array(cr.holder).filter_map { |h| text_content(h.content) }.join(", ")
          parts = []
          parts << years if years && !years.empty?
          parts << holders if holders && !holders.empty?
          parts.any? ? parts.join(" ") : nil
        end.join("; ")
      end

      def text_content(content)
        return nil unless content

        text = content.is_a?(Array) ? content.join : content.to_s
        text.strip.empty? ? nil : text.strip
      end

      def root_element_name
        # Derive from the class name — Book, Article, Chapter, etc.
        @document.class.name.split("::").last.gsub(/(?<!^)([A-Z])/, '_\1').downcase
      end
    end
  end
end
