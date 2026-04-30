# frozen_string_literal: true

require "uri"

module Docbook
  module Mirror
    module Handlers
      class Inline
        # Process inline content from an element that supports each_mixed_content
        def self.process(element, context:)
          return [] unless element.respond_to?(:each_mixed_content)

          children = []
          element.each_mixed_content do |node|
            case node
            when String
              text = node
              children << Node::Text.new(text: text) unless text.empty?
            when Docbook::Elements::Emphasis
              children << emphasis(node, context: context)
            when Docbook::Elements::Literal, Docbook::Elements::Code,
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
              children << code(node, context: context)
            when Docbook::Elements::Link
              children << link(node, context: context)
            when Docbook::Elements::Xref
              children << xref(node, context: context)
            when Docbook::Elements::Quote
              children.concat(quote(node, context: context))
            when Docbook::Elements::Tag
              children << tag(node, context: context)
            when Docbook::Elements::Biblioref
              children << biblioref(node, context: context)
            when Docbook::Elements::FirstTerm, Docbook::Elements::Glossterm
              children << firstterm(node, context: context)
            when Docbook::Elements::Citetitle
              children << citetitle(node, context: context)
            when Docbook::Elements::Inlinemediaobject
              children << Handlers::Media.inline_image(node, context: context)
            when Docbook::Elements::ProductName
              children << productname(node, context: context)
            when Docbook::Elements::Trademark
              children << trademark(node, context: context)
            when Docbook::Elements::Email
              children << email(node, context: context)
            when Docbook::Elements::Uri
              children << uri(node, context: context)
            when Docbook::Elements::Subscript
              children << subscript(node, context: context)
            when Docbook::Elements::Superscript
              children << superscript(node, context: context)
            when Docbook::Elements::KeyCap
              children << keycap(node, context: context)
            when Docbook::Elements::Abbrev, Docbook::Elements::Phrase,
                 Docbook::Elements::Application, Docbook::Elements::WordAsWord,
                 Docbook::Elements::Date, Docbook::Elements::ReleaseInfo
              children << plain_text(node, context: context)
            when Docbook::Elements::CiterefEntry
              children << citerefentry(node, context: context)
            when Docbook::Elements::Footnote
              children << Handlers::Footnote.call(node, context: context)
            when Docbook::Elements::FootnoteRef
              children << Handlers::Footnote.ref(node, context: context)
            else
              # Catch-all: try to extract text content from any unhandled inline element
              if node.respond_to?(:content) && node.content.any?
                children << Node::Text.new(text: node.content.join)
              elsif node.respond_to?(:text) && node.text
                children << Node::Text.new(text: node.text.to_s)
              end
            end
          end
          children
        end

        # -- Individual inline element handlers --

        def self.emphasis(el, context:)
          role = el.role
          mark = if %w[bold strong].include?(role)
                   Mark::Strong.new
                 elsif role == "italic"
                   Mark::Italic.new
                 else
                   Mark::Emphasis.new
                 end
          text = el.content.join
          context.text_node(text, marks: [mark])
        end

        def self.code(el, context:)
          role = code_role(el)
          text = context.extract_text(el)
          context.text_node(text, marks: [Mark::Code.new(role: role)])
        end

        def self.link(el, context:)
          xml_id_map = context.instance_variable_get(:@xml_id_map)
          href = el.xlink_href&.to_s || (el.linkend ? "##{el.linkend}" : "#")

          # Handle self-closing links with no content
          if el.content.join.empty? && !has_inline_children(el)
            # For linkend references, resolve the title from xml_id_map
            if el.linkend
              text = xml_id_map[el.linkend.to_s] || el.linkend.to_s
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
            text = context.extract_text(el)
          end

          link_mark = if el.linkend
                        Mark::Link.new(linkend: el.linkend)
                      else
                        Mark::Link.new(href: href)
                      end

          context.text_node(text, marks: [link_mark])
        end

        def self.xref(el, context:)
          xml_id_map = context.instance_variable_get(:@xml_id_map)
          linkend = el.linkend.to_s
          resolved_title = xml_id_map[linkend] || linkend
          context.text_node(
            resolved_title,
            marks: [Mark::Xref.new(linkend: linkend,
                                   resolved: resolved_title)],
          )
        end

        def self.quote(el, context:)
          children = []
          return children unless el.respond_to?(:each_mixed_content)

          el.each_mixed_content do |node|
            case node
            when String
              text = node
              children << Node::Text.new(text: text) unless text.empty?
            when Docbook::Elements::Emphasis
              children << emphasis(node, context: context)
            when Docbook::Elements::Literal, Docbook::Elements::Code,
                 Docbook::Elements::UserInput, Docbook::Elements::ComputerOutput,
                 Docbook::Elements::Filename, Docbook::Elements::ClassName,
                 Docbook::Elements::Function, Docbook::Elements::Parameter,
                 Docbook::Elements::Replaceable
              children << code(node, context: context)
            when Docbook::Elements::Link
              children << link(node, context: context)
            when Docbook::Elements::Xref
              children << xref(node, context: context)
            when Docbook::Elements::Tag
              children << tag(node, context: context)
            when Docbook::Elements::Biblioref
              children << biblioref(node, context: context)
            when Docbook::Elements::FirstTerm, Docbook::Elements::Glossterm
              children << firstterm(node, context: context)
            end
          end
          children
        end

        def self.tag(el, context:)
          tag_name = el.content.join
          text = "<#{tag_name}>"
          context.text_node(text, marks: [Mark::Code.new(role: "tag")])
        end

        def self.biblioref(el, context:)
          linkend = el.linkend.to_s
          text = el.content.join.empty? ? linkend : el.content.join
          context.text_node(text,
                            marks: [Mark::Citation.new(bibref: linkend)])
        end

        def self.firstterm(el, context:)
          text = context.extract_text(el)
          context.text_node(text, marks: [Mark::Emphasis.new])
        end

        def self.citetitle(el, context:)
          text = el.content.join
          context.text_node(text,
                            marks: [Mark::Citation.new(bibref: el.href)])
        end

        def self.productname(el, context:)
          text = el.content.join
          suffix = case el.class_name
                   when "trade" then "\u2122"
                   when "registered" then "\u00AE"
                   when "copyright" then "\u00A9"
                   when "service" then "\u2120"
                   else ""
                   end
          full_text = text + suffix
          if el.href
            context.text_node(full_text,
                              marks: [Mark::Link.new(attrs: { href: el.href })])
          else
            context.text_node(full_text, marks: [Mark::Strong.new])
          end
        end

        def self.trademark(el, context:)
          text = el.content.join
          suffix = case el.class_name
                   when "trade" then "\u2122"
                   when "registered" then "\u00AE"
                   when "copyright" then "\u00A9"
                   when "service" then "\u2120"
                   else "\u2122"
                   end
          context.text_node(text + suffix)
        end

        def self.email(el, context:)
          text = el.content.join
          context.text_node(text,
                            marks: [Mark::Link.new(href: "mailto:#{text}")])
        end

        def self.uri(el, context:)
          text = el.content.join
          context.text_node(text, marks: [Mark::Link.new(href: text)])
        end

        def self.subscript(el, context:)
          text = el.content.join
          context.text_node(text, marks: [Mark.new(type: "subscript")])
        end

        def self.superscript(el, context:)
          text = el.content.join
          context.text_node(text, marks: [Mark.new(type: "superscript")])
        end

        def self.keycap(el, context:)
          text = el.content.join
          context.text_node(text,
                            marks: [Mark::Code.new(role: "keycap")])
        end

        def self.plain_text(el, context:)
          text = el.content.join
          context.text_node(text)
        end

        def self.citerefentry(el, context:)
          title = el.refentrytitle&.content&.join
          manvol = el.manvolnum&.content&.join
          text = manvol.empty? ? title : "#{title}(#{manvol})"
          context.text_node(text)
        end

        class << self
          private

          def has_inline_children(el)
            return false unless el.respond_to?(:each_mixed_content)

            el.each_mixed_content do |node|
              return true if node.is_a?(Lutaml::Model::Serializable)
            end
            false
          end

          def code_role(el)
            case el
            when Docbook::Elements::Literal then "literal"
            when Docbook::Elements::Code then "code"
            when Docbook::Elements::UserInput then "userinput"
            when Docbook::Elements::ComputerOutput then "computeroutput"
            when Docbook::Elements::Filename then "filename"
            when Docbook::Elements::ClassName then "classname"
            when Docbook::Elements::Function then "function"
            when Docbook::Elements::Parameter then "parameter"
            when Docbook::Elements::Replaceable then "replaceable"
            when Docbook::Elements::Command then "command"
            when Docbook::Elements::Option then "option"
            when Docbook::Elements::Envar then "envar"
            when Docbook::Elements::Property then "property"
            when Docbook::Elements::Varname then "varname"
            when Docbook::Elements::Type then "type"
            when Docbook::Elements::Errortype then "errortype"
            when Docbook::Elements::Errorcode then "errorcode"
            when Docbook::Elements::Exceptionname then "exceptionname"
            when Docbook::Elements::Constant then "constant"
            when Docbook::Elements::Prompt then "prompt"
            when Docbook::Elements::BuildTarget then "buildtarget"
            when Docbook::Elements::Enumvalue then "enumvalue"
            else "literal"
            end
          end
        end
      end
    end
  end
end
