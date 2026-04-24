# frozen_string_literal: true

module Docbook
  module Output
    # Renders a DocbookMirror guide hash as semantic HTML.
    #
    # Produces the same HTML structure and CSS classes as the Vue MirrorRenderer,
    # enabling server-side rendering for SEO and split-page output.
    #
    # Usage:
    #   guide = Pipeline.new(xml_path: "book.xml").process
    #   html = HtmlRenderer.new(guide).render
    #
    class HtmlRenderer
      SECTION_TYPES = %w[
        chapter section appendix part preface dedication
        acknowledgements colophon reference refentry
      ].freeze

      SECTION_HEADING_LEVELS = {
        "part" => 1, "chapter" => 2, "section" => 3,
        "appendix" => 2, "preface" => 2, "dedication" => 2,
        "reference" => 1, "refentry" => 2, "refsection" => 3,
        "acknowledgements" => 2, "colophon" => 2
      }.freeze

      ADMONITION_TITLES = {
        "note" => "Note", "warning" => "Warning",
        "tip" => "Tip", "caution" => "Caution",
        "important" => "Important", "danger" => "Danger"
      }.freeze

      def initialize(guide)
        @guide = guide
        @content = guide["content"] || []
        @numbering = guide.dig("toc", "numbering") || {}
      end

      # Render the full document content as HTML
      def render
        render_nodes(@content)
      end

      # Render a subset of content nodes
      def render_nodes(nodes)
        nodes.map { |node| render_node(node) }.join("\n")
      end

      private

      def render_node(node)
        type = node["type"]
        method = :"render_#{type}"
        return send(method, node) if respond_to?(method, true)

        render_generic(node)
      end

      # --- Structural / recursive ---

      def render_doc(node)
        render_children(node)
      end

      def render_generic(node)
        children = node["content"]
        return "" unless children

        render_children(node)
      end

      # --- Section types ---

      def render_chapter(node) = render_section_like(node)
      def render_section(node) = render_section_like(node)
      def render_appendix(node) = render_section_like(node)
      def render_part(node) = render_section_like(node)
      def render_preface(node) = render_section_like(node)
      def render_dedication(node) = render_section_like(node)
      def render_acknowledgements(node) = render_section_like(node)
      def render_colophon(node) = render_section_like(node)
      def render_reference(node) = render_section_like(node)
      def render_refentry(node) = render_section_like(node)

      def render_section_like(node)
        type = node["type"]
        attrs = node["attrs"] || {}
        xml_id = attrs["xml_id"]
        title = attrs["title"]
        level = SECTION_HEADING_LEVELS[type] || 3

        id_attr = xml_id ? %( id="#{e(xml_id)}") : ""
        number = @numbering[xml_id]
        number_prefix = number ? "#{number} " : ""
        heading = ""
        if title
          heading = %(<h#{level}#{id_attr} class="db-#{type}__title">#{number_prefix}#{e(title)}</h#{level}>)
        end

        content = render_children(node)
        %(<section class="db-#{type}">\n  #{heading}\n  #{content}\n</section>)
      end

      def render_refsection(node)
        title = node.dig("attrs", "title")
        heading = title ? %(<h3 class="db-refsection__title">#{e(title)}</h3>) : ""
        %(<div class="db-refsection">\n  #{heading}\n  #{render_children(node)}\n</div>)
      end

      # --- Block elements ---

      def render_paragraph(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        content = render_inline(node["content"])
        %(<p#{id_attr} class="db-paragraph">#{content}</p>)
      end

      def render_code_block(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        text = attrs["text"] || ""
        lang = attrs["language"]
        lang_class = lang ? " language-#{lang}" : ""
        title = attrs["title"]
        number = @numbering[attrs["xml_id"]]

        header = ""
        if title || number
          label = number ? "Example #{number}" : ""
          label += ": " if number && title
          label += title if title
          header = %(\n  <div class="db-code-block__header">#{e(label)}</div>)
        end
        lang_badge = lang ? %(  <span class="code-language-badge">#{e(lang)}</span>\n) : ""

        code = e(text)
        %(<div#{id_attr} class="db-code-block#{lang_class}">#{lang_badge}#{header}\n  <pre class="code-block"><code>#{code}</code></pre>\n</div>)
      end

      def render_blockquote(node)
        content = render_children(node)
        %(<blockquote class="db-blockquote">\n  #{content}\n</blockquote>)
      end

      def render_ordered_list(node)
        items = (node["content"] || []).map do |item|
          next render_node(item) unless item["type"] == "list_item"

          %(<li class="db-list-item">#{render_children(item)}</li>)
        end.join("\n")
        %(<ol class="db-ordered-list">\n  #{items}\n</ol>)
      end

      def render_bullet_list(node)
        items = (node["content"] || []).map do |item|
          next render_node(item) unless item["type"] == "list_item"

          %(<li class="db-list-item">#{render_children(item)}</li>)
        end.join("\n")
        %(<ul class="db-bullet-list">\n  #{items}\n</ul>)
      end

      def render_dl(node)
        items = (node["content"] || []).map do |item|
          case item["type"]
          when "definition_term"
            %(<dt class="db-dt">#{render_children(item)}</dt>)
          when "definition_description"
            %(<dd class="db-dd">#{render_children(item)}</dd>)
          else
            render_node(item)
          end
        end.join("\n")
        %(<dl class="db-definition-list">\n  #{items}\n</dl>)
      end

      def render_image(node)
        attrs = node["attrs"] || {}
        src = attrs["src"] || ""
        alt = attrs["alt"] || ""
        title = attrs["title"]
        xml_id = attrs["xml_id"]
        id_attr = xml_id ? %( id="#{e(xml_id)}") : ""
        number = @numbering[xml_id]

        img = %(<img src="#{e(src)}" alt="#{e(alt)}" loading="lazy" />)
        return %(<div#{id_attr} class="db-image">#{img}</div>) unless title || number

        caption = ""
        if number || title
          caption = number ? "Figure #{number}" : ""
          caption += ": " if number && title
          caption += title if title
        end
        %(<figure#{id_attr} class="db-figure">\n  #{img}\n  <figcaption>#{e(caption)}</figcaption>\n</figure>)
      end

      def render_admonition(node)
        attrs = node["attrs"] || {}
        admonition_type = attrs["admonition_type"] || "note"
        title = ADMONITION_TITLES[admonition_type] || admonition_type.capitalize
        content = render_children(node)
        <<~HTML
          <div class="db-admonition db-admonition--#{admonition_type}">
          <div class="admonition-content">
          <div class="admonition-title">#{e(title)}</div>
          #{content}
          </div></div>
        HTML
      end

      def render_table(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        number = @numbering[attrs["xml_id"]]

        header = ""
        if title || number
          label = number ? "Table #{number}" : ""
          label += ": " if number && title
          label += title if title
          header = %(<div class="db-table__header">#{e(label)}</div>)
        end

        content = node["content"] || []
        thead = render_table_section(content.select { |s| s["type"] == "table_head" }, "th")
        tbody = render_table_section(content.select { |s| s["type"] == "table_body" }, "td")

        %(<div#{id_attr} class="db-table">#{header}\n  <table>\n#{thead}#{tbody}\n  </table>\n</div>)
      end

      def render_equation(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        number = @numbering[attrs["xml_id"]]

        header = ""
        if title || number
          label = number ? "Equation #{number}" : ""
          label += ": " if number && title
          label += title if title
          header = %(<div class="db-equation__header">#{e(label)}</div>)
        end

        content = render_children(node)
        %(<div#{id_attr} class="db-equation">#{header}\n  #{content}\n</div>)
      end

      def render_sidebar(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<div class="sidebar-title">#{e(title)}</div>) : ""
        content = render_children(node)
        %(<aside#{id_attr} class="db-sidebar">#{heading}\n  #{content}\n</aside>)
      end

      def render_procedure(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<div class="db-procedure__title">#{e(title)}</div>) : ""
        content = render_children(node)
        %(<div#{id_attr} class="db-procedure">#{heading}\n  <ol class="procedure-list">\n    #{content}\n  </ol>\n</div>)
      end

      def render_step(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        content = render_children(node)
        %(<li#{id_attr} class="step-item">#{content}</li>)
      end

      def render_substeps(node)
        content = render_children(node)
        %(<li class="substeps-item"><ol class="procedure-list">\n  #{content}\n</ol></li>)
      end

      def render_calloutlist(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<div>#{e(title)}</div>) : ""
        content = render_children(node)
        %(<div#{id_attr} class="db-calloutlist">#{heading}\n  <ol class="callout-list">\n    #{content}\n  </ol>\n</div>)
      end

      def render_callout(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        content = render_children(node)
        %(<li#{id_attr} class="callout-item">#{content}</li>)
      end

      def render_qandaset(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<h3>#{e(title)}</h3>) : ""
        content = render_children(node)
        %(<section#{id_attr} class="db-qandaset">#{heading}\n  #{content}\n</section>)
      end

      def render_qandaentry(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        content = render_children(node)
        %(<div#{id_attr} class="db-qandaentry">#{content}</div>)
      end

      def render_question(node)
        content = render_children(node)
        %(<div class="db-question"><div class="question-label">Q:</div><div class="question-content">#{content}</div></div>)
      end

      def render_answer(node)
        content = render_children(node)
        %(<div class="db-answer"><div class="answer-label">A:</div><div class="answer-content">#{content}</div></div>)
      end

      # --- Glossary ---

      def render_glossary(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<h2>#{e(title)}</h2>) : ""
        content = render_children(node)
        %(<section#{id_attr} class="db-glossary">#{heading}\n  #{content}\n</section>)
      end

      def render_gloss_entry(node)
        render_children(node)
      end

      def render_gloss_term(node)
        content = render_children(node)
        %(<dt class="db-gloss-term">#{content}</dt>)
      end

      def render_gloss_def(node)
        content = render_children(node)
        %(<dd class="db-gloss-def">#{content}</dd>)
      end

      def render_gloss_see(node)
        text = extract_text(node)
        otherterm = node.dig("attrs", "otherterm")
        link = otherterm ? %(<a href="##{e(otherterm)}">#{e(text)}</a>) : e(text)
        %(<dd class="db-gloss-see">See: #{link}</dd>)
      end

      def render_gloss_see_also(node)
        text = extract_text(node)
        otherterm = node.dig("attrs", "otherterm")
        link = otherterm ? %(<a href="##{e(otherterm)}">#{e(text)}</a>) : e(text)
        %(<dd class="db-gloss-see-also">See also: #{link}</dd>)
      end

      # --- Bibliography ---

      def render_bibliography(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<h2>#{e(title)}</h2>) : ""
        content = render_children(node)
        %(<section#{id_attr} class="db-bibliography">#{heading}\n  #{content}\n</section>)
      end

      def render_biblio_entry(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        content = render_inline(node["content"])
        %(<div#{id_attr} class="db-biblio-entry">#{content}</div>)
      end

      # --- Index ---

      def render_index_block(node)
        attrs = node["attrs"] || {}
        id_attr = attrs["xml_id"] ? %( id="#{e(attrs["xml_id"])}") : ""
        title = attrs["title"]
        heading = title ? %(<h2>#{e(title)}</h2>) : ""
        content = render_children(node)
        %(<section#{id_attr} class="db-index">#{heading}\n  #{content}\n</section>)
      end

      def render_index_div(node)
        title = node.dig("attrs", "title")
        heading = title ? %(<h3>#{e(title)}</h3>) : ""
        content = render_children(node)
        %(<div class="db-index-div">#{heading}\n  #{content}\n</div>)
      end

      def render_index_entry(node)
        content = render_inline(node["content"])
        %(<div class="db-index-entry">#{content}</div>)
      end

      # --- Footnotes ---

      def render_footnotes(node)
        items = (node["content"] || []).map do |fn|
          id = fn.dig("attrs", "id")
          ref_id = fn.dig("attrs", "ref_id")
          id_attr = id ? %( id="#{e(id)}") : ""
          backref = ref_id ? %( <a href="##{e(ref_id)}">&#8617;</a>) : ""
          content = render_children(fn)
          %(<li#{id_attr}>#{content}#{backref}</li>)
        end.join("\n")
        %(<div class="footnotes"><ol>\n  #{items}\n</ol></div>)
      end

      # --- Misc ---

      def render_soft_break(_node)
        "<br />"
      end

      def render_annotation(_node)
        # Annotations are interactive-only; render nothing in static HTML
        ""
      end

      def render_synopsis(node)
        content = render_children(node)
        %(<div class="db-synopsis">#{content}</div>)
      end

      # --- Table helpers ---

      def render_table_section(sections, cell_tag)
        sections.map do |section|
          rows = (section["content"] || []).map do |row|
            cells = (row["content"] || []).map do |cell|
              content = render_inline(cell["content"])
              cell_attrs = cell["attrs"] || {}
              colspan = cell_attrs["nameend"] ? %( colspan="#{colspan_value(cell_attrs)}") : ""
              rowspan = cell_attrs["morerows"] ? %( rowspan="#{cell_attrs["morerows"].to_i + 1}") : ""
              %(<#{cell_tag}#{colspan}#{rowspan}>#{content}</#{cell_tag}>)
            end.join
            %(<tr>#{cells}</tr>)
          end.join("\n")
          tag = cell_tag == "th" ? "thead" : "tbody"
          %(    <#{tag}>\n      #{rows}\n    </#{tag}>\n)
        end.join
      end

      def colspan_value(attrs)
        # Simplified: if nameend is specified, assume 2 columns
        attrs["nameend"] ? "2" : ""
      end

      # --- Inline rendering ---

      def render_inline(content)
        return "" unless content
        return "" if content.empty?

        content.map do |node|
          if node.is_a?(String)
            e(node)
          elsif node["type"] == "text"
            render_text_node(node)
          elsif node["type"] == "footnote_marker"
            attrs = node["attrs"] || {}
            id = attrs["id"]
            ref_id = attrs["ref_id"]
            id_attr = id ? %( id="#{e(id)}") : ""
            %(<sup class="footnote-marker"><a#{id_attr} href="##{e(ref_id || "")}">#{e(attrs["number"] || "*")}</a></sup>)
          elsif node["type"] == "soft_break"
            "<br />"
          else
            render_node(node)
          end
        end.join
      end

      def render_text_node(node)
        text = e(node["text"] || "")
        marks = node["marks"] || []
        marks.reduce(text) { |current, mark| apply_mark(current, mark) }
      end

      def apply_mark(text, mark)
        case mark["type"]
        when "emphasis"  then "<em>#{text}</em>"
        when "strong"    then "<strong>#{text}</strong>"
        when "italic"    then "<i>#{text}</i>"
        when "code"
          role = mark.dig("attrs", "role")
          cls = role ? %( class="db-inline-code role-#{e(role)}") : %( class="db-inline-code")
          "<code#{cls}>#{text}</code>"
        when "link"
          href = mark.dig("attrs", "href") || "#"
          %(<a href="#{e(href)}">#{text}</a>)
        when "xref"
          linkend = mark.dig("attrs", "linkend") || ""
          resolved = mark.dig("attrs", "resolved") || ""
          display = if resolved.empty?
                      text
                    else
                      (text.empty? ? e(resolved) : text)
                    end
          %(<a href="##{e(linkend)}">#{display}</a>)
        when "citation"
          bibref = mark.dig("attrs", "bibref") || ""
          %(<a href="##{e(bibref)}">#{text}</a>)
        when "subscript"    then "<sub>#{text}</sub>"
        when "superscript"  then "<sup>#{text}</sup>"
        else text
        end
      end

      # --- Helpers ---

      def render_children(node)
        children = node["content"] || []
        render_nodes(children)
      end

      def extract_text(node)
        return node["text"] || "" if node["type"] == "text"

        (node["content"] || []).map { |child| extract_text(child) }.join
      end

      def e(text)
        return "" unless text

        text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
      end
    end
  end
end
