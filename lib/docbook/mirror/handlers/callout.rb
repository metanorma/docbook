# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Callout
        def self.list(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          callouts = (element.callout if element.respond_to?(:callout)).to_a.filter_map { |c| callout(c, context) }
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
