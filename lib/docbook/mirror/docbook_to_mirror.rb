# frozen_string_literal: true

require "uri"

module Docbook
  module Mirror
    # Transforms DocBook element tree into DocbookMirror node tree.
    #
    # This is the forward direction of the transformation: DocBook XML elements
    # are converted into ProseMirror-style JSON node tree suitable for the Vue
    # frontend's MirrorRenderer.
    #
    # Uses a HandlerRegistry for dispatch, making it extensible without
    # modifying this class. The default registry maps all built-in DocBook
    # elements to their handlers.
    #
    # Usage:
    #   doc = Docbook::Document.from_xml(xml_string)
    #   mirror_doc = DocbookToMirror.new.call(doc)
    #
    class DocbookToMirror
      include Docbook::Services::ElementIdHelper

      attr_reader :registry

      def initialize(sort_glossary: false, registry: Docbook::Mirror.default_registry)
        @sort_glossary = sort_glossary
        @registry = registry
        @xml_id_map = {}
        @footnote_counter = 0
        @footnotes = []
      end

      # Entry point: Convert DocBook document to DocbookMirror
      def call(docbook_doc)
        @xml_id_map = build_xml_id_map(docbook_doc)
        @footnote_counter = 0
        @footnotes = []
        document_node(docbook_doc)
      end

      # =========================================
      # Context API — methods available to handlers via context:
      # =========================================

      def document_node(docbook_doc)
        title = if docbook_doc.respond_to?(:info) && docbook_doc.info.respond_to?(:title)
                  docbook_doc.info.title&.content&.join
                elsif docbook_doc.respond_to?(:title)
                  docbook_doc.title&.content&.join
                end

        attrs = { title: title }.compact
        content = extract_content(docbook_doc)

        Docbook::Mirror::Node::Document.new(attrs: attrs, content: content)
      end

      # Extract content nodes from an element using the handler registry.
      # Iterates mixed content, dispatching each DocBook element to its
      # registered handler. Unknown elements are silently skipped.
      def extract_content(element)
        content = []
        return content unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          case node
          when String
            next if node.strip.empty?
          else
            handle_node(node, content)
          end
        end
        content.compact
      end

      # =========================================
      # Inline Processing (delegated to Handlers::Inline)
      # =========================================

      def process_inline_content(element)
        Handlers::Inline.process(element, context: self)
      end

      # Paragraph handler used by annotation and others that need paragraph_node directly
      def paragraph_handler(para)
        Handlers::Paragraph.call(para, context: self)
      end

      # =========================================
      # Shared Helpers (used by handlers via context)
      # =========================================

      def text_node(text, marks: [])
        Node::Text.new(text: text, marks: marks)
      end

      def extract_text(element)
        return element.content.join unless element.respond_to?(:each_mixed_content)

        texts = []
        element.each_mixed_content do |node|
          if node.is_a?(String)
            texts << node
          elsif node.respond_to?(:content)
            texts << node.content.join
          end
        end
        texts.join
      end

      def extract_co_markers(element)
        markers = []
        counter = 0
        return markers unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          next if node.is_a?(String)
          next unless node.is_a?(Docbook::Elements::Co)

          counter += 1
          id = node.xml_id if node.respond_to?(:xml_id)
          label = node.respond_to?(:label) && node.label ? node.label : counter.to_s
          markers << { number: counter, id: id, label: label }.compact
        end
        markers
      end

      def extract_text_with_callouts(element, co_markers)
        return element.content.join unless element.respond_to?(:each_mixed_content)

        marker_idx = 0
        texts = []
        element.each_mixed_content do |node|
          if node.is_a?(String)
            texts << node
          elsif node.is_a?(Docbook::Elements::Co)
            marker = co_markers[marker_idx]
            texts << "(#{marker[:label]})"
            marker_idx += 1
          elsif node.respond_to?(:content)
            texts << node.content.join
          end
        end
        texts.join
      end

      def link_node(element)
        Handlers::Inline.link(element, context: self)
      end

      def citetitle_node(element)
        Handlers::Inline.citetitle(element, context: self)
      end

      # =========================================
      # Footnote Management
      # =========================================

      def register_footnote(element)
        @footnote_counter += 1
        num = @footnote_counter
        fn_id = "fn-#{num}"
        ref_id = "fn-ref-#{num}"

        fn_content = if element.respond_to?(:para) && element.para.any?
                       element.para.filter_map { |p| paragraph_handler(p) }
                     elsif element.respond_to?(:each_mixed_content)
                       process_inline_content(element)
                     else
                       [text_node(extract_text(element))]
                     end

        @footnotes << {
          id: fn_id,
          ref_id: ref_id,
          number: num,
          xml_id: element.xml_id,
          content: fn_content,
        }

        Node.new(
          type: "footnote_marker",
          attrs: { id: fn_id, ref_id: ref_id, number: num },
        )
      end

      def resolve_footnoteref(element)
        linkend = element.linkend if element.respond_to?(:linkend)
        ref_fn = @footnotes.find { |fn| fn[:xml_id] == linkend } if linkend

        if ref_fn
          Node.new(
            type: "footnote_marker",
            attrs: { id: ref_fn[:id], ref_id: "fn-ref-#{ref_fn[:number]}-dup-#{@footnote_counter}", number: ref_fn[:number] },
          )
        else
          text_node("[footnote]")
        end
      end

      def flush_footnotes
        return nil if @footnotes.empty?

        entries = @footnotes.map do |fn|
          Node.new(
            type: "footnote_entry",
            attrs: { id: fn[:id], ref_id: fn[:ref_id], number: fn[:number] },
            content: fn[:content],
          )
        end

        @footnotes = []
        Node.new(type: "footnotes", content: entries)
      end

      # =========================================
      # XML ID Map
      # =========================================

      def build_xml_id_map(doc)
        map = {}
        return map unless doc.respond_to?(:each_mixed_content)

        doc.each_mixed_content do |node|
          next if node.is_a?(String)

          id = element_id(node)
          map[id] = resolve_title(node) if id && !id.empty?

          build_xml_id_map(node).each { |k, v| map[k] = v }
        end
        map
      end

      def resolve_title(node)
        title = case node
                when Docbook::Elements::RefEntry
                  resolve_refentry_title(node)
                when Docbook::Elements::Bibliomixed
                  node.abbrev&.content&.join || node.citetitle&.first&.then { |ct| ct&.content&.join }
                else
                  t = node.title&.content&.join if node.respond_to?(:title)
                  t || (node.info&.title&.then { |ti| ti&.content&.join } if node.respond_to?(:info))
                end
        flatten_title(title)
      end

      def flatten_title(title)
        case title
        when Array then title.map { |t| t.is_a?(String) ? t : t.to_s }.join
        when String then title
        else title.to_s
        end
      end

      private

      # Dispatch a single node through the handler registry.
      def handle_node(node, content)
        result = @registry.handle(node, context: self)
        return unless result

        value, concat = result
        return unless value

        if concat
          content.concat(Array(value))
        else
          content << value
        end
      end
    end
  end
end
