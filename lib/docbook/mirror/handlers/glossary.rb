# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Glossary
        def self.call(element, context:)
          attrs = {
            xml_id: element.xml_id,
            title: element.title&.content&.join,
          }.compact
          raw_entries = (element.glossentry if element.respond_to?(:glossentry)).to_a
          entries = raw_entries.filter_map { |entry| glossentry(entry, context) }
          entries = sort_glossary_entries(entries) if context.instance_variable_get(:@sort_glossary)
          Node::Glossary.new(attrs: attrs, content: entries)
        end

        class << self
          private

          def glossentry(entry, context)
            attrs = { xml_id: entry.xml_id }.compact
            content = []

            if entry.respond_to?(:glossterm) && entry.glossterm
              term_text = entry.glossterm.content.join
              content << Node::GlossTerm.new(content: [context.text_node(term_text)])
            end

            if entry.respond_to?(:glossdef) && entry.glossdef
              def_content = context.extract_content(entry.glossdef)
              content << Node::GlossDef.new(content: def_content) unless def_content.empty?
            end

            if entry.respond_to?(:glosssee) && entry.glosssee
              Array(entry.glosssee).each do |gs|
                text = gs.content.join
                attrs_see = { otherterm: gs.otherterm }.compact
                content << Node::GlossSee.new(attrs: attrs_see, content: [context.text_node(text)])
              end
            end

            if entry.respond_to?(:glossseealso) && entry.glossseealso
              Array(entry.glossseealso).each do |gsa|
                text = gsa.content.join
                attrs_see = { otherterm: gsa.otherterm }.compact
                content << Node::GlossSeeAlso.new(attrs: attrs_see, content: [context.text_node(text)])
              end
            end

            return nil if content.empty?

            Node::GlossEntry.new(attrs: attrs, content: content)
          end

          def sort_glossary_entries(entries)
            entries.sort_by do |entry|
              term_node = entry.content&.find { |n| n.is_a?(Node::GlossTerm) }
              term_text = term_node&.content&.filter_map { |n| n.text if n.respond_to?(:text) }&.join&.downcase || ""
              term_text
            end
          end
        end
      end
    end
  end
end
