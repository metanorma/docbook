# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 1b: Assign synthetic xml:id to formal elements (tables, figures,
      # examples) that lack one. Ensures list-of entries have link targets.
      class AssignIds
        FORMAL_TYPES = [
          Elements::Table, Elements::InformalTable,
          Elements::Figure, Elements::InformalFigure,
          Elements::Example, Elements::InformalExample
        ].freeze

        def call(guide, context)
          @counter = 0
          assign_recursive(context.parsed)
          guide
        end

        private

        def assign_recursive(node)
          return unless node.is_a?(Lutaml::Model::Serializable)

          if FORMAL_TYPES.any? { |t| node.is_a?(t) } && has_title?(node) && node.respond_to?(:xml_id) && node.xml_id.nil?
            @counter += 1
            node.xml_id = "lo-#{@counter}"
          end

          return unless node.class.respond_to?(:attributes)

          node.class.attributes.each_value do |attr_def|
            value = node.send(attr_def.name)
            next if value.nil?

            case value
            when Array
              value.each { |v| assign_recursive(v) if walkable?(v) }
            else
              assign_recursive(value) if walkable?(value)
            end
          end
        end

        def walkable?(value)
          value.is_a?(Lutaml::Model::Serializable)
        end

        def has_title?(node)
          node.respond_to?(:title) && node.title &&
            node.title.content&.join&.strip && node.title.content.join.strip != ""
        end
      end
    end
  end
end
