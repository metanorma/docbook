# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Callout
        def self.list(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          callouts = (el.callout if el.respond_to?(:callout)).to_a.filter_map { |c| callout(c, context) }
          Node::CalloutList.new(attrs: attrs, content: callouts)
        end

        class << self
          private

          def callout(c, context)
            attrs = {
              xml_id: c.xml_id,
              arearefs: c.arearefs,
            }.compact
            content = context.extract_content(c)
            return nil if content.empty?

            Node::Callout.new(attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
