# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class QandASet
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          entries = Array(element.qandaentry).filter_map { |e| qandaentry(e, context) }
          return nil if entries.empty?

          Node.new(type: "qandaset", attrs: attrs, content: entries)
        end

        class << self
          private

          def qandaentry(element, context)
            attrs = { xml_id: element.xml_id }.compact
            content = []
            if element.question
              q_content = context.extract_content(element.question)
              content << Node.new(type: "question", attrs: {}, content: q_content) unless q_content.empty?
            end
            Array(element.answer).each do |a|
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
