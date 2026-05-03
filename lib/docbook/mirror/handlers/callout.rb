# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Callout
        def self.list(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          callouts = element.callout.to_a.filter_map do |c|
            callout(c, context)
          end
          Node::CalloutList.new(attrs: attrs, content: callouts)
        end

        class << self
          private

          def callout(node, context)
            attrs = {
              xml_id: node.xml_id,
              arearefs: node.arearefs,
            }.compact
            content = context.extract_content(node)
            return nil if content.empty?

            Node::Callout.new(attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
