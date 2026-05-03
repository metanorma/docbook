# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Index
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          content = []

          if element.indexdiv&.any?
            element.indexdiv.each { |div| content << indexdiv_node(div) }
          end

          if element.indexentry&.any?
            element.indexentry.each do |entry|
              content << indexentry_node(entry)
            end
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
            entries = div.indexentry.to_a.filter_map do |entry|
              indexentry_node(entry)
            end
            Node::IndexDiv.new(attrs: attrs, content: entries)
          end

          def indexentry_node(entry)
            attrs = { xml_id: entry.xml_id }.compact
            content = []
            if entry.primaryie
              content << Node::Text.new(text: entry.primaryie.to_s)
            end
            if entry.secondaryie
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
