# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Index
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          content = []

          if element.respond_to?(:indexdiv) && element.indexdiv&.any?
            element.indexdiv.each { |div| content << indexdiv_node(div) }
          end

          if element.respond_to?(:indexentry) && element.indexentry&.any?
            element.indexentry.each { |entry| content << indexentry_node(entry) }
          end

          Node::IndexBlock.new(attrs: attrs, content: content)
        end

        class << self
          private

          def indexdiv_node(div)
            attrs = {
              xml_id: div.xml_id,
              title: div.title&.content&.join,
            }.compact
            entries = (div.indexentry if div.respond_to?(:indexentry)).to_a.filter_map { |entry| indexentry_node(entry) }
            Node::IndexDiv.new(attrs: attrs, content: entries)
          end

          def indexentry_node(entry)
            attrs = { xml_id: entry.xml_id }.compact
            content = []
            if entry.respond_to?(:primaryie) && entry.primaryie
              content << Node::Text.new(text: entry.primaryie.to_s)
            end
            if entry.respond_to?(:secondaryie) && entry.secondaryie
              content << Node::Text.new(text: entry.secondaryie.to_s)
            end
            return nil if content.empty?

            Node::IndexEntry.new(attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
