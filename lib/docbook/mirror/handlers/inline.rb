# frozen_string_literal: true

require "uri"

module Docbook
  module Mirror
    module Handlers
      class Inline
        # Registry mapping element classes to [method_symbol, concat_flag].
        # Third-party code can add entries to extend inline handling (OCP).
        HANDLER_MAP = {}.tap do |h|
          h[Docbook::Elements::Emphasis] = [:emphasis, false]
          h[Docbook::Elements::Link] = [:link, false]
          h[Docbook::Elements::Xref] = [:xref, false]
          h[Docbook::Elements::Quote] = [:quote, true]
          h[Docbook::Elements::Tag] = [:tag, false]
          h[Docbook::Elements::Biblioref] = [:biblioref, false]
          h[Docbook::Elements::FirstTerm] = [:firstterm, false]
          h[Docbook::Elements::Glossterm] = [:firstterm, false]
          h[Docbook::Elements::Citetitle] = [:citetitle, false]
          h[Docbook::Elements::Inlinemediaobject] = [:inline_image, false]
          h[Docbook::Elements::ProductName] = [:productname, false]
          h[Docbook::Elements::Trademark] = [:trademark, false]
          h[Docbook::Elements::Email] = [:email, false]
          h[Docbook::Elements::Uri] = [:uri, false]
          h[Docbook::Elements::Subscript] = [:subscript, false]
          h[Docbook::Elements::Superscript] = [:superscript, false]
          h[Docbook::Elements::KeyCap] = [:keycap, false]
          h[Docbook::Elements::CiterefEntry] = [:citerefentry, false]
          h[Docbook::Elements::Footnote] = [:footnote, false]
          h[Docbook::Elements::FootnoteRef] = [:footnoteref, false]

          # Code-style elements → all use the :code handler
          [
            Docbook::Elements::Literal, Docbook::Elements::Code,
            Docbook::Elements::UserInput, Docbook::Elements::ComputerOutput,
            Docbook::Elements::Filename, Docbook::Elements::ClassName,
            Docbook::Elements::Function, Docbook::Elements::Parameter,
            Docbook::Elements::Replaceable,
            Docbook::Elements::Command, Docbook::Elements::Option,
            Docbook::Elements::Envar, Docbook::Elements::Property,
            Docbook::Elements::Varname, Docbook::Elements::Type,
            Docbook::Elements::Errortype, Docbook::Elements::Errorcode,
            Docbook::Elements::Exceptionname, Docbook::Elements::Constant,
            Docbook::Elements::Prompt, Docbook::Elements::BuildTarget,
            Docbook::Elements::Enumvalue
          ].each { |k| h[k] = [:code, false] }

          # Plain text elements → all use the :plain_text handler
          [
            Docbook::Elements::Abbrev, Docbook::Elements::Phrase,
            Docbook::Elements::Application, Docbook::Elements::WordAsWord,
            Docbook::Elements::Date, Docbook::Elements::ReleaseInfo
          ].each { |k| h[k] = [:plain_text, false] }
        end.freeze

        def self.process(element, context:)
          return [] unless element.is_a?(Lutaml::Model::Serializable)

          children = []
          element.each_mixed_content do |node|
            if node.is_a?(String)
              children << Node::Text.new(text: node) unless node.empty?
            else
              dispatch_inline(node, children, context)
            end
          end
          children
        end

        class << self
          private

          def dispatch_inline(node, children, context)
            entry = HANDLER_MAP[node.class]
            if entry
              method_name, concat = entry
              result = send(method_name, node, context: context)
              concat ? children.concat(Array(result)) : (children << result if result)
            else
              fallback_text(node, children)
            end
          end

          def fallback_text(node, children)
            if node.content&.any?
              children << Node::Text.new(text: node.content.join)
            elsif node.text
              children << Node::Text.new(text: node.text.to_s)
            end
          end
        end

        # -- Individual inline element handlers --

        def self.emphasis(element, context:)
          role = element.role
          mark = if %w[bold strong].include?(role)
                   Mark::Strong.new
                 elsif role == "italic"
                   Mark::Italic.new
                 else
                   Mark::Emphasis.new
                 end
          text = element.content.join
          context.text_node(text, marks: [mark])
        end

        def self.code(element, context:)
          role = code_role(element)
          text = context.extract_text(element)
          context.text_node(text, marks: [Mark::Code.new(role: role)])
        end

        def self.link(element, context:)
          xml_id_map = context.xml_id_map
          href = element.xlink_href&.to_s || (element.linkend ? "##{element.linkend}" : "#")

          # Handle self-closing links with no content
          if element.content.join.empty? && !has_inline_children?(element)
            # For linkend references, resolve the title from xml_id_map
            if element.linkend
              text = xml_id_map[element.linkend.to_s] || element.linkend.to_s
            else
              uri = begin
                URI(href)
              rescue StandardError
                nil
              end
              text = if uri&.path && !uri.path.empty? && uri.path != "/"
                       File.basename(uri.path)
                     elsif uri&.host
                       uri.host
                     else
                       href
                     end
            end
          else
            text = context.extract_text(element)
          end

          link_mark = if element.linkend
                        Mark::Link.new(linkend: element.linkend)
                      else
                        Mark::Link.new(href: href)
                      end

          context.text_node(text, marks: [link_mark])
        end

        def self.xref(element, context:)
          xml_id_map = context.xml_id_map
          linkend = element.linkend.to_s
          resolved_title = xml_id_map[linkend] || linkend
          context.text_node(
            resolved_title,
            marks: [Mark::Xref.new(linkend: linkend,
                                   resolved: resolved_title)],
          )
        end

        def self.quote(element, context:)
          process(element, context: context)
        end

        def self.tag(element, context:)
          tag_name = element.content.join
          text = "<#{tag_name}>"
          context.text_node(text, marks: [Mark::Code.new(role: "tag")])
        end

        def self.biblioref(element, context:)
          linkend = element.linkend.to_s
          text = element.content.join.empty? ? linkend : element.content.join
          context.text_node(text,
                            marks: [Mark::Citation.new(bibref: linkend)])
        end

        def self.firstterm(element, context:)
          text = context.extract_text(element)
          context.text_node(text, marks: [Mark::Emphasis.new])
        end

        def self.citetitle(element, context:)
          text = element.content.join
          context.text_node(text,
                            marks: [Mark::Citation.new(bibref: element.href)])
        end

        def self.productname(element, context:)
          text = element.content.join
          suffix = case element.class_name
                   when "trade" then "\u2122"
                   when "registered" then "\u00AE"
                   when "copyright" then "\u00A9"
                   when "service" then "\u2120"
                   else ""
                   end
          full_text = text + suffix
          if element.href
            context.text_node(full_text,
                              marks: [Mark::Link.new(attrs: { href: element.href })])
          else
            context.text_node(full_text, marks: [Mark::Strong.new])
          end
        end

        def self.trademark(element, context:)
          text = element.content.join
          suffix = case element.class_name
                   when "registered" then "\u00AE"
                   when "copyright" then "\u00A9"
                   when "service" then "\u2120"
                   else "\u2122"
                   end
          context.text_node(text + suffix)
        end

        def self.email(element, context:)
          text = element.content.join
          context.text_node(text,
                            marks: [Mark::Link.new(href: "mailto:#{text}")])
        end

        def self.uri(element, context:)
          text = element.content.join
          context.text_node(text, marks: [Mark::Link.new(href: text)])
        end

        def self.subscript(element, context:)
          text = element.content.join
          context.text_node(text, marks: [Mark.new(type: "subscript")])
        end

        def self.superscript(element, context:)
          text = element.content.join
          context.text_node(text, marks: [Mark.new(type: "superscript")])
        end

        def self.keycap(element, context:)
          text = element.content.join
          context.text_node(text,
                            marks: [Mark::Code.new(role: "keycap")])
        end

        def self.plain_text(element, context:)
          text = element.content.join
          context.text_node(text)
        end

        def self.citerefentry(element, context:)
          title = element.refentrytitle&.content&.join
          manvol = element.manvolnum&.content&.join
          text = manvol.empty? ? title : "#{title}(#{manvol})"
          context.text_node(text)
        end

        # Cross-handler delegation wrappers (for registry uniformity)
        def self.inline_image(element, context:)
          Handlers::Media.inline_image(element, context: context)
        end

        def self.footnote(element, context:)
          Handlers::Footnote.call(element, context: context)
        end

        def self.footnoteref(element, context:)
          Handlers::Footnote.ref(element, context: context)
        end

        class << self
          private

          def has_inline_children?(element)
            element.each_mixed_content do |node|
              return true if node.is_a?(Lutaml::Model::Serializable)
            end
            false
          end

          def code_role(element)
            element.class.name.split("::").last.downcase
          end
        end
      end
    end
  end
end
