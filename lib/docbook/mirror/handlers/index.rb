# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Index
        def self.call(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          content = []

          if el.respond_to?(:indexdiv) && el.indexdiv&.any?
            el.indexdiv.each { |div| content << indexdiv_node(div) }
          end

          if el.respond_to?(:indexentry) && el.indexentry&.any?
            el.indexentry.each { |ie| content << indexentry_node(ie) }
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
            entries = (div.indexentry if div.respond_to?(:indexentry)).to_a.filter_map { |ie| indexentry_node(ie) }
            Node::IndexDiv.new(attrs: attrs, content: entries)
          end

          def indexentry_node(ie)
            attrs = { xml_id: ie.xml_id }.compact
            content = []
            if ie.respond_to?(:primaryie) && ie.primaryie
              content << Node::Text.new(text: ie.primaryie.to_s)
            end
            if ie.respond_to?(:secondaryie) && ie.secondaryie
              content << Node::Text.new(text: ie.secondaryie.to_s)
            end
            return nil if content.empty?

            Node::IndexEntry.new(attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
