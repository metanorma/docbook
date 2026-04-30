# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Bibliography
        def self.call(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          entries = (el.bibliomixed if el.respond_to?(:bibliomixed)).to_a.filter_map { |bm| biblio_entry(bm, context) }
          Node::Bibliography.new(attrs: attrs, content: entries)
        end

        def self.bibliolist(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          entries = (el.bibliomixed if el.respond_to?(:bibliomixed)).to_a.filter_map { |bm| biblio_entry(bm, context) }
          Node::Bibliography.new(attrs: attrs, content: entries)
        end

        class << self
          private

          def biblio_entry(bm, context)
            attrs = {
              xml_id: bm.xml_id,
              role: bm.role,
            }.compact

            parts = []
            if bm.respond_to?(:abbrev) && bm.abbrev
              parts << context.text_node(bm.abbrev.content.join, marks: [Mark::Strong.new])
              parts << context.text_node(". ")
            end
            if bm.respond_to?(:citetitle) && bm.citetitle&.any?
              bm.citetitle.each do |ct|
                parts << context.citetitle_node(ct)
                parts << context.text_node(". ")
              end
            end
            if bm.respond_to?(:author) && bm.author&.any?
              authors = bm.author.filter_map { |a| a.personname&.content&.join }.join(", ")
              unless authors.empty?
                parts << context.text_node(authors)
                parts << context.text_node(". ")
              end
            end
            if bm.respond_to?(:publishername) && bm.publishername&.any?
              publishers = bm.publishername.filter_map(&:content).join(", ")
              unless publishers.empty?
                parts << context.text_node(publishers)
                parts << context.text_node(". ")
              end
            end
            if bm.respond_to?(:pubdate) && bm.pubdate
              parts << context.text_node(bm.pubdate.to_s)
              parts << context.text_node(". ")
            end
            if bm.respond_to?(:link) && bm.link&.any?
              bm.link.each do |l|
                parts << context.link_node(l)
                parts << context.text_node(". ")
              end
            end
            # Remove trailing separator
            parts.pop if parts.last&.text == ". "

            # Fallback: raw content
            if parts.empty?
              text = context.extract_text(bm)
              parts << context.text_node(text) unless text.empty?
            end

            return nil if parts.empty?

            Node::BiblioEntry.new(attrs: attrs, content: parts)
          end
        end
      end
    end
  end
end
