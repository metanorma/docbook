# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class QandASet
        def self.call(el, context:)
          attrs = {
            xml_id: el.xml_id,
            title: el.title&.content&.join,
          }.compact
          entries = Array(el.qandaentry).filter_map { |e| qandaentry(e, context) }
          return nil if entries.empty?

          Node.new(type: "qandaset", attrs: attrs, content: entries)
        end

        class << self
          private

          def qandaentry(el, context)
            attrs = { xml_id: el.xml_id }.compact
            content = []
            if el.question
              q_content = context.extract_content(el.question)
              content << Node.new(type: "question", attrs: {}, content: q_content) unless q_content.empty?
            end
            Array(el.answer).each do |a|
              a_content = context.extract_content(a)
              content << Node.new(type: "answer", attrs: {}, content: a_content) unless a_content.empty?
            end
            return nil if content.empty?

            Node.new(type: "qandaentry", attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
