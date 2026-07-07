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
          "title" => @document.resolve_title,
          "subtitle" => extract_subtitle,
          "author" => extract_author,
          "pubdate" => extract_pubdate,
          "releaseinfo" => extract_releaseinfo,
          "copyright" => extract_copyright,
          "cover" => extract_cover,
          "root_element" => root_element_name,
          **counts,
        }
      end

      private

      SECTION_KEY = "sections"

      CATEGORY_MAP = {
        image: "images",
        code_block: "code_blocks",
        table: "tables",
        index_term: "index_terms",
        bibliography_entry: "bibliography_entries",
      }.freeze

      def walk(node, counts)
        if node.section_like?
          counts[SECTION_KEY] += 1
        else
          key = CATEGORY_MAP[node.stats_category]
          counts[key] += 1 if key
        end

        node.walk_children { |child| walk(child, counts) }
      end

      def extract_author
        info = @document.info
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
        text_content(@document.info&.subtitle&.content)
      end

      def extract_pubdate
        text_content(@document.info&.pubdate&.content)
      end

      def extract_releaseinfo
        releaseinfo = Array(@document.info&.releaseinfo).first
        text_content(releaseinfo&.content)
      end

      def extract_copyright
        copyrights = @document.info&.copyright
        return unless copyrights && !copyrights.empty?

        copyrights.filter_map do |cr|
          years = Array(cr.year).filter_map do |y|
            text_content(y.content)
          end.join(", ")
          holders = Array(cr.holder).filter_map do |h|
            text_content(h.content)
          end.join(", ")
          parts = []
          parts << years if years && !years.empty?
          parts << holders if holders && !holders.empty?
          parts.any? ? parts.join(" ") : nil
        end.join("; ")
      end

      def extract_cover
        info = @document.info
        return unless info&.cover && !info.cover.empty?

        first_cover = info.cover.first
        return unless first_cover.mediaobject && !first_cover.mediaobject.empty?

        first_media = first_cover.mediaobject.first
        return unless first_media.imageobject && !first_media.imageobject.empty?

        first_image = first_media.imageobject.first
        first_image.imagedata&.fileref
      end

      def text_content(content)
        return nil unless content

        text = content.is_a?(Array) ? content.join : content.to_s
        text.strip.empty? ? nil : text.strip
      end

      def root_element_name
        @document.class.name.split("::").last.gsub(/(?<!^)([A-Z])/,
                                                   '_\1').downcase
      end
    end
  end
end
