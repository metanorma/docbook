# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 2: Generate table of contents from parsed document.
      class GenerateToc
        def call(guide, context)
          toc_tree = Services::TocGenerator.new(context.parsed).generate
          toc_sections = toc_tree.map { |node| toc_node_to_hash(node) }
          guide["toc_sections_raw"] = toc_sections
          guide
        end

        private

        def toc_node_to_hash(node)
          result = {
            "id" => node.id,
            "title" => node.title,
            "type" => node.type,
            "number" => node.number,
          }
          if node.children&.any?
            result["children"] = node.children.map do |c|
              toc_node_to_hash(c)
            end
          end
          result.compact
        end
      end
    end
  end
end
