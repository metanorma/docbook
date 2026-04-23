# 03 — HTML Renderer

## Goal

Create a Ruby-side HTML renderer that walks the DocbookMirror node tree and produces semantic HTML. This enables two output formats:
- **DOM format**: pre-rendered HTML embedded in a single-page HTML for SEO
- **Paged format**: split content across multiple HTML files

## Current State

All HTML rendering happens client-side in Vue:
- `MirrorRenderer.vue` (602 lines) — dispatches ~30 block types to HTML elements
- `TextRenderer.vue` — handles inline text with marks (emphasis, code, links, etc.)
- `SectionBlock.vue` — renders section/chapter/part headings with anchors

There is **no Ruby-side HTML renderer**. The `<body>` of the output HTML is just an empty `<div id="docbook-app"></div>`.

## Design

### OCP Compliance
Use a dispatch table (hash of type → renderer method) so adding a new node type means adding one entry, not modifying existing rendering logic. The renderer is open for extension (new node types), closed for modification (existing renderers unchanged).

### Encapsulation
The `HtmlRenderer` encapsulates the complete mapping from mirror nodes to HTML. It takes a guide hash and returns an HTML string. No knowledge of file I/O, CSS, or JavaScript.

### Model-Driven
The renderer's input is the guide hash — the same data model that Vue consumes. It doesn't re-parse XML. The mirror node type system (`paragraph`, `code_block`, `admonition`, etc.) is the contract.

### File: New `lib/docbook/output/html_renderer.rb`

```ruby
module Docbook
  module Output
    class HtmlRenderer
      def initialize(guide)
        @guide = guide
        @content = guide["content"] || []
      end

      # Render the full document content as HTML
      def render
        html_blocks = @content.map { |node| render_node(node) }
        html_blocks.join("\n")
      end

      # Render a subset of content (for paged mode — one section)
      def render_nodes(nodes)
        nodes.map { |node| render_node(node) }.join("\n")
      end

      private

      # Dispatch table — maps node type to renderer method
      # Open for extension: add new types by adding to this hash
      BLOCK_RENDERERS = {
        "paragraph" => :render_paragraph,
        "code_block" => :render_code_block,
        "blockquote" => :render_blockquote,
        "bullet_list" => :render_bullet_list,
        "ordered_list" => :render_ordered_list,
        "list_item" => :render_list_item,
        "dl" => :render_definition_list,
        "image" => :render_image,
        "admonition" => :render_admonition,
        "table" => :render_table,
        "equation" => :render_equation,
        "sidebar" => :render_sidebar,
        "procedure" => :render_procedure,
        "calloutlist" => :render_callout_list,
        "qandaset" => :render_qandaset,
        "footnotes" => :render_footnotes,
        # Section-like types
        "chapter" => :render_section,
        "section" => :render_section,
        "appendix" => :render_section,
        "part" => :render_section,
        "preface" => :render_section,
        "dedication" => :render_section,
        "acknowledgements" => :render_section,
        "colophon" => :render_section,
        "reference" => :render_section,
        "refentry" => :render_section,
        "refsection" => :render_section,
        # Glossary / Bibliography / Index
        "glossary" => :render_glossary,
        "bibliography" => :render_bibliography,
        "index_block" => :render_index_block,
      }.freeze

      def render_node(node)
        type = node["type"]
        renderer = BLOCK_RENDERERS[type]
        return "" unless renderer
        send(renderer, node)
      end

      # --- Block renderers ---
      # Each produces semantic HTML using the same CSS classes as the Vue MirrorRenderer
      # so the existing app.css styles apply.

      def render_paragraph(node)
        content = render_inline(node["content"])
        %(<p class="db-paragraph">#{content}</p>)
      end

      def render_code_block(node)
        lang = node.dig("attrs", "language")
        lang_class = lang ? " language-#{lang}" : ""
        code = escape_html(node.dig("attrs", "text") || "")
        title = node.dig("attrs", "title")
        header = title ? %(\n  <div class="db-code-block__header">#{escape_html(title)}</div>) : ""
        %(<pre class="db-code-block#{lang_class}">#{header}\n  <code>#{code}</code>\n</pre>)
      end

      def render_blockquote(node)
        content = render_children(node)
        attribution = node.dig("attrs", "attribution")
        attr_html = attribution ? %(\n  <cite>#{escape_html(attribution)}</cite>) : ""
        %(<blockquote class="db-blockquote">\n  #{content}#{attr_html}\n</blockquote>)
      end

      def render_bullet_list(node)
        items = render_children(node)
        %(<ul class="db-bullet-list">\n  #{items}\n</ul>)
      end

      def render_ordered_list(node)
        items = render_children(node)
        numeration = node.dig("attrs", "numeration")
        attrs = numeration ? %( type="#{numeration}") : ""
        %(<ol class="db-ordered-list"#{attrs}>\n  #{items}\n</ol>)
      end

      def render_list_item(node)
        content = render_children(node)
        %(<li class="db-list-item">\n  #{content}\n</li>)
      end

      def render_definition_list(node)
        content = render_children(node)
        %(<dl class="db-definition-list">\n  #{content}\n</dl>)
      end

      def render_image(node)
        src = node.dig("attrs", "src") || ""
        alt = node.dig("attrs", "alt") || ""
        title = node.dig("attrs", "title")
        xml_id = node.dig("attrs", "xml_id")
        id_attr = xml_id ? %( id="#{xml_id}") : ""
        title_attr = title ? %( title="#{escape_html(title)}") : ""
        fig_class = title ? "db-figure" : "db-image"
        img = %(<img#{id_attr} src="#{escape_html(src)}" alt="#{escape_html(alt)}"#{title_attr} />)
        return img unless title
        %(<figure class="#{fig_class}">\n  #{img}\n  <figcaption>#{escape_html(title)}</figcaption>\n</figure>)
      end

      def render_admonition(node)
        admonition_type = node.dig("attrs", "admonition_type") || "note"
        title = node.dig("attrs", "title")
        content = render_children(node)
        title_html = title ? %(\n  <div class="db-admonition__title">#{escape_html(title)}</div>) : ""
        %(<div class="db-admonition db-admonition--#{admonition_type}">#{title_html}\n  <div class="db-admonition__content">\n    #{content}\n  </div>\n</div>)
      end

      def render_section(node)
        type = node["type"]
        title = node.dig("attrs", "title") || ""
        xml_id = node.dig("attrs", "xml_id") || ""
        number = node.dig("attrs", "number")

        # Map section type to heading level (approximate — Vue uses depth tracking)
        level = section_heading_level(type, node)
        id_attr = xml_id.empty? ? "" : %( id="#{xml_id}")
        number_prefix = number ? "#{number} " : ""

        heading = %(<h#{level}#{id_attr} class="db-#{type}__title">#{number_prefix}#{escape_html(title)}</h#{level}>)
        content = render_children(node)
        %(<section class="db-#{type}">\n  #{heading}\n  #{content}\n</section>)
      end

      def render_table(node)
        # Delegate to helper that handles thead/tbody/tfoot/rows/cells
        # ... (follows same structure as Vue table rendering)
      end

      # ... (remaining block renderers follow same pattern)

      # --- Inline rendering ---
      # Mirrors Vue TextRenderer.vue logic

      def render_inline(content)
        return "" unless content
        return "" if content.empty?

        content.map do |node|
          if node.is_a?(String)
            escape_html(node)
          elsif node["type"] == "text"
            render_text_node(node)
          else
            render_node(node)  # inline image, etc.
          end
        end.join
      end

      def render_text_node(node)
        text = escape_html(node["text"] || "")
        marks = node["marks"] || []
        marks.reduce(text) do |current, mark|
          apply_mark(current, mark)
        end
      end

      def apply_mark(text, mark)
        case mark["type"]
        when "emphasis" then "<em>#{text}</em>"
        when "strong"   then "<strong>#{text}</strong>"
        when "italic"   then "<i>#{text}</i>"
        when "code"     then %(<code class="db-inline-code">#{text}</code>)
        when "link"     then %(<a href="#{escape_html(mark.dig("attrs", "href") || "#")}">#{text}</a>)
        when "xref"     then %(<a href="##{escape_html(mark.dig("attrs", "linkend") || "")}">#{text}</a>)
        when "subscript" then "<sub>#{text}</sub>"
        when "superscript" then "<sup>#{text}</sup>"
        else text
        end
      end

      # --- Helpers ---

      def render_children(node)
        children = node["content"] || []
        render_nodes(children)
      end

      def escape_html(text)
        return "" unless text
        text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
      end

      SECTION_LEVELS = {
        "part" => 1, "chapter" => 2, "section" => 3,
        "appendix" => 2, "preface" => 2, "dedication" => 2,
        "reference" => 1, "refentry" => 2, "refsection" => 3,
        "acknowledgements" => 2, "colophon" => 2,
      }.freeze

      def section_heading_level(type, _node)
        SECTION_LEVELS[type] || 3
      end
    end
  end
end
```

## Design Notes

### Why not reuse Vue's rendering via SSR?
Vue SSR would require a Node.js runtime dependency, which violates the gem's "pure Ruby" design. The Ruby renderer produces equivalent HTML using the same CSS classes.

### Why a dispatch table instead of case/when?
OCP: adding a new node type = adding one hash entry + one method. No modification to the dispatch logic.

### CSS class compatibility
The renderer uses the same `db-*` CSS classes as the Vue components. This means `app.css` works for both JSON-rendered and pre-rendered HTML output.

### Heading levels
The Ruby renderer uses a simplified heading level map (part=1, chapter=2, section=3). The Vue renderer tracks depth dynamically. For SEO purposes, the simplified mapping is sufficient — the important thing is that headings exist in the DOM.

## Verification

1. Render `spec/fixtures/kitchen-sink/kitchen-sink.xml` via Pipeline + HtmlRenderer
2. Compare output structure to what Vue renders (same CSS classes, same semantic elements)
3. Validate the HTML is well-formed
4. Verify text content matches the source XML
