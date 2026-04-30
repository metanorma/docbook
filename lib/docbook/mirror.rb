# frozen_string_literal: true

module Docbook
  module Mirror
    class Error < StandardError; end

    autoload :Version, "#{__dir__}/mirror/version"
    autoload :Node, "#{__dir__}/mirror/node"
    autoload :Mark, "#{__dir__}/mirror/mark"
    autoload :Transformer, "#{__dir__}/mirror/transformer"
    autoload :DocbookToMirror, "#{__dir__}/mirror/docbook_to_mirror"
    autoload :MirrorToDocbook, "#{__dir__}/mirror/mirror_to_docbook"
    autoload :HandlerRegistry, "#{__dir__}/mirror/handler_registry"
    autoload :Handlers, "#{__dir__}/mirror/handlers"

    # Build the default handler registry with all built-in handlers.
    # Third-party code can add handlers to this registry, or create
    # a custom registry and pass it to DocbookToMirror.
    def self.default_registry
      registry = HandlerRegistry.new

      # ── Paragraphs ──
      registry.register(Docbook::Elements::Para, Handlers::Paragraph)
      registry.register(Docbook::Elements::FormalPara,
                        ->(el, ctx) { ctx.paragraph_handler(el.para) if el.para })

      # ── Code ──
      registry.register(Docbook::Elements::Code, Handlers::CodeBlock)
      registry.register(Docbook::Elements::ProgramListing, Handlers::CodeBlock)
      registry.register(Docbook::Elements::Screen, Handlers::CodeBlock, extra_kwargs: { language: "text" })
      registry.register(Docbook::Elements::LiteralLayout, Handlers::CodeBlock, extra_kwargs: { language: "text" })

      # ── Blocks ──
      registry.register(Docbook::Elements::BlockQuote, Handlers::Blockquote)
      registry.register(Docbook::Elements::Example, Handlers::Example)
      registry.register(Docbook::Elements::InformalExample, Handlers::Example, method_name: :informal)
      registry.register(Docbook::Elements::Address, Handlers::Example, method_name: :address)
      registry.register(Docbook::Elements::LegalNotice, Handlers::Example, method_name: :legalnotice)

      # ── Lists ──
      registry.register(Docbook::Elements::OrderedList, Handlers::List, method_name: :ordered)
      registry.register(Docbook::Elements::ItemizedList, Handlers::List, method_name: :bullet)
      registry.register(Docbook::Elements::VariableList, Handlers::List, method_name: :definition)

      # ── Media ──
      registry.register(Docbook::Elements::Figure, Handlers::Media, method_name: :figure)
      registry.register(Docbook::Elements::InformalFigure, Handlers::Media, method_name: :figure)

      # ── Tables ──
      registry.register(Docbook::Elements::Table, Handlers::Table)
      registry.register(Docbook::Elements::InformalTable, Handlers::Table)

      # ── Admonitions ──
      registry.register(Docbook::Elements::Note, Handlers::Admonition)
      registry.register(Docbook::Elements::Warning, Handlers::Admonition)
      registry.register(Docbook::Elements::Tip, Handlers::Admonition)
      registry.register(Docbook::Elements::Caution, Handlers::Admonition)
      registry.register(Docbook::Elements::Important, Handlers::Admonition)
      registry.register(Docbook::Elements::Danger, Handlers::Admonition)

      # ── Sections ──
      registry.register(Docbook::Elements::Section, Handlers::Section, method_name: :section)
      registry.register(Docbook::Elements::Chapter, Handlers::Section, method_name: :chapter)
      registry.register(Docbook::Elements::Appendix, Handlers::Section, method_name: :appendix)
      registry.register(Docbook::Elements::Part, Handlers::Section, method_name: :part)
      registry.register(Docbook::Elements::Preface, Handlers::Section, method_name: :preface)
      registry.register(Docbook::Elements::Dedication,
                        ->(el, ctx) { Handlers::Section.titled_section(el, context: ctx, node_class: Node::Preface) })
      registry.register(Docbook::Elements::Acknowledgements,
                        ->(el, ctx) { Handlers::Section.titled_section(el, context: ctx, node_class: Node::Acknowledgements) })
      registry.register(Docbook::Elements::Colophon,
                        ->(el, ctx) { Handlers::Section.titled_section(el, context: ctx, node_class: Node::Colophon) })
      registry.register(Docbook::Elements::Simplesect, Handlers::Section, method_name: :simplesect)
      registry.register(Docbook::Elements::Sect1, Handlers::Section, method_name: :sect)
      registry.register(Docbook::Elements::Sect2, Handlers::Section, method_name: :sect)
      registry.register(Docbook::Elements::Sect3, Handlers::Section, method_name: :sect)
      registry.register(Docbook::Elements::Sect4, Handlers::Section, method_name: :sect)
      registry.register(Docbook::Elements::Sect5, Handlers::Section, method_name: :sect)

      # ── Structural ──
      registry.register(Docbook::Elements::Set, Handlers::Structural, method_name: :set)
      registry.register(Docbook::Elements::Article, Handlers::Structural, method_name: :article)
      registry.register(Docbook::Elements::Topic, Handlers::Structural, method_name: :topic)

      # ── Reference ──
      registry.register(Docbook::Elements::Reference, Handlers::Reference, method_name: :reference)
      registry.register(Docbook::Elements::RefEntry, Handlers::Reference, method_name: :refentry)
      registry.register(Docbook::Elements::RefNamediv, Handlers::Reference, method_name: :refnamediv, concat: true)
      registry.register(Docbook::Elements::RefSection, Handlers::Reference, method_name: :refsection)
      registry.register(Docbook::Elements::RefSect1, Handlers::Reference, method_name: :refsection)
      registry.register(Docbook::Elements::RefSect2, Handlers::Reference, method_name: :refsection)
      registry.register(Docbook::Elements::RefSect3, Handlers::Reference, method_name: :refsection)

      # ── Content blocks ──
      registry.register(Docbook::Elements::Procedure, Handlers::Procedure)
      registry.register(Docbook::Elements::SideBar, Handlers::Sidebar)
      registry.register(Docbook::Elements::Annotation, Handlers::Annotation)
      registry.register(Docbook::Elements::Footnote, Handlers::Footnote)
      registry.register(Docbook::Elements::Equation, Handlers::Equation)
      registry.register(Docbook::Elements::QandASet, Handlers::QandASet)
      registry.register(Docbook::Elements::CalloutList, Handlers::Callout, method_name: :list)

      # ── Back matter ──
      registry.register(Docbook::Elements::Glossary, Handlers::Glossary)
      registry.register(Docbook::Elements::Bibliography, Handlers::Bibliography)
      registry.register(Docbook::Elements::Bibliolist, Handlers::Bibliography, method_name: :bibliolist)
      registry.register(Docbook::Elements::Index, Handlers::Index)
      registry.register(Docbook::Elements::SetIndex, Handlers::Index)

      registry
    end
  end
end
