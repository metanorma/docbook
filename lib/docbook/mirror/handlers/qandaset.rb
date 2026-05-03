# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class QandASet
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: context.resolve_title(element),
          }.compact
          entries = Array(element.qandaentry).filter_map do |e|
            qandaentry(e, context)
          end
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
              unless q_content.empty?
                content << Node.new(type: "question", attrs: {},
                                    content: q_content)
              end
            end
            Array(element.answer).each do |a|
              a_content = context.extract_content(a)
              unless a_content.empty?
                content << Node.new(type: "answer", attrs: {},
                                    content: a_content)
              end
            end
            return nil if content.empty?

            Node.new(type: "qandaentry", attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
