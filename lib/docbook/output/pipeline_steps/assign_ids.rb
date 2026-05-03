# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      class AssignIds
        def call(guide, context)
          @counter = 0
          assign_recursive(context.parsed)
          guide
        end

        private

        def assign_recursive(node)
          if node.formal? && node.has_title? && node.xml_id.nil?
            @counter += 1
            node.xml_id = "lo-#{@counter}"
          end

          node.walk_children { |child| assign_recursive(child) }
        end
      end
    end
  end
end
