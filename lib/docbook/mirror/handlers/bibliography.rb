# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Bibliography
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          entries = element.bibliomixed.to_a.filter_map do |entry|
            biblio_entry(entry, context)
          end
          Node::Bibliography.new(attrs: attrs, content: entries)
        end

        class << self
          alias bibliolist call

          private

          def biblio_entry(entry, context)
            attrs = {
              xml_id: entry.xml_id,
              role: entry.role,
            }.compact

            parts = []
            if entry.abbrev
              parts << context.text_node(entry.abbrev.content.join, marks: [Mark::Strong.new])
              parts << context.text_node(". ")
            end
            if entry.citetitle&.any?
              entry.citetitle.each do |ct|
                parts << context.citetitle_node(ct)
                parts << context.text_node(". ")
              end
            end
            if entry.author&.any?
              authors = entry.author.filter_map do |a|
                a.personname&.content&.join
              end.join(", ")
              unless authors.empty?
                parts << context.text_node(authors)
                parts << context.text_node(". ")
              end
            end
            if entry.publishername&.any?
              publishers = entry.publishername.filter_map(&:content).join(", ")
              unless publishers.empty?
                parts << context.text_node(publishers)
                parts << context.text_node(". ")
              end
            end
            if entry.pubdate
              parts << context.text_node(entry.pubdate.to_s)
              parts << context.text_node(". ")
            end
            if entry.link&.any?
              entry.link.each do |l|
                parts << context.link_node(l)
                parts << context.text_node(". ")
              end
            end
            # Remove trailing separator
            parts.pop if parts.last&.text == ". "

            # Fallback: raw content
            if parts.empty?
              text = context.extract_text(entry)
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
