# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Procedure
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          steps = (element.step if element.respond_to?(:step)).to_a.filter_map { |s| step_node(s, context) }
          Node::Procedure.new(attrs: attrs, content: steps)
        end

        class << self
          private

          def step_node(step, context)
            attrs = { xml_id: step.xml_id }.compact
            content = context.extract_content(step)

            if step.respond_to?(:substeps) && step.substeps&.any?
              step.substeps.each do |ss|
                sub_steps = (ss.step if ss.respond_to?(:step)).to_a.filter_map { |st| step_node(st, context) }
                content << Node::SubSteps.new(content: sub_steps) unless sub_steps.empty?
              end
            end

            return nil if content.empty?

            Node::Step.new(attrs: attrs, content: content)
          end
        end
      end
    end
  end
end
