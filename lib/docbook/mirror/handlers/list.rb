# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class List
        # Ordered list
        def self.ordered(el, context:)
          items = el.listitem.to_a.filter_map { |li| list_item(li, context) }
          return nil if items.empty?

          Node::OrderedList.new(content: items)
        end

        # Bullet (itemized) list
        def self.bullet(el, context:)
          items = el.listitem.to_a.filter_map { |li| list_item(li, context) }
          return nil if items.empty?

          Node::BulletList.new(content: items)
        end

        # Variable (definition) list
        def self.definition(el, context:)
          entries = el.varlistentry.to_a.flat_map do |ve|
            definition_entry(ve, context)
          end
          return nil if entries.empty?

          Node::DefinitionList.new(content: entries)
        end

        class << self
          private

          def list_item(li, context)
            content = context.extract_content(li)
            return nil if content.empty?

            Node::ListItem.new(content: content)
          end

          def definition_entry(ve, context)
            term_node = build_term(ve, context)
            desc_node = build_desc(ve, context)
            return nil unless term_node || desc_node

            [term_node, desc_node].compact
          end

          def build_term(ve, context)
            return nil unless ve.respond_to?(:term)

            term_content = context.process_inline_content(ve.term) if ve.term
            return nil if term_content.empty?

            Node::DefinitionTerm.new(content: term_content)
          end

          def build_desc(ve, context)
            li = ve.listitem if ve.respond_to?(:listitem)
            return nil unless li

            desc_content = context.extract_content(li)
            return nil if desc_content.empty?

            Node::DefinitionDescription.new(content: desc_content)
          end
        end
      end
    end
  end
end
