# frozen_string_literal: true

require "erb"
require "fileutils"
require "liquid"
require "marcel"
require_relative "data"
require_relative "index_generator"

module Docbook
  module Output
    TEMPLATE_PATH = File.join(__dir__, "..", "templates", "document.html.liquid")
    TEMPLATES_ROOT = File.join(__dir__, "..", "templates")
    FRONTEND_ROOT = File.expand_path("../../../frontend/dist", __dir__)

    # Configure Liquid template engine with file system for includes
    # Liquid::LocalFileSystem root should be the templates directory
    # When using {% include 'partials/head' %}, it looks for {root}/partials/_head.liquid
    Liquid::Environment.default.file_system = Liquid::LocalFileSystem.new(TEMPLATES_ROOT)

    class Html
      TEMPLATE_PATH = File.join(__dir__, "..", "templates", "document.html.liquid")
      FRONTEND_ROOT = File.expand_path("../../../frontend/dist", __dir__)

      def initialize(document, xref_resolver: nil, output_mode: :single_file, base_path: nil, output_path: nil)
        @document = document
        @xref_resolver = xref_resolver
        @output_mode = output_mode
        @base_path = base_path
        @output_path = output_path
        @image_cache = {}
        @index_collector = IndexCollector.new(document)
      end

      def to_html
        sections_data = collect_sections
        numbering_hash = build_numbering_map(sections_data)
        all_index_terms = @index_collector.collect
        content_hash = build_content_map(sections_data, all_index_terms)

        # Build the output model
        output = DocbookOutput.new(
          title: extract_title,
          toc: Toc.new(
            sections: sections_data,
            numbering: numbering_hash.map { |id, value| NumberingEntry.new(id: id, value: value) }
          ),
          content: ContentData.new(
            entries: content_hash.map { |key, value| ContentEntry.new(key: key, value: value) }
          ),
          index: build_index(all_index_terms)
        )

        template_content = File.read(TEMPLATE_PATH)

        if @output_mode == :directory
          # Write full DocbookOutput as JSON for Vue to fetch
          FileUtils.mkdir_p(@output_path) if @output_path
          data_path = @output_path ? File.join(@output_path, "docbook.data.json") : "docbook.data.json"
          File.write(data_path, output.to_json)

          template = Liquid::Template.parse(template_content)
          rendered = template.render(
            "docbook_title" => output.title || "DocBook Document",
            "base_url" => base_url,
            "assets_inline" => false,
            "app_css" => File.read(File.join(FRONTEND_ROOT, "app.css")),
            "app_js" => File.read(File.join(FRONTEND_ROOT, "app.iife.js")),
            "data_url" => "docbook.data.json"
          )
          rendered = rendered.gsub('[[DOCBOOK_DATA]]', 'null /* loaded from docbook.data.json */')
                             .gsub('[[DOCBOOK_TOC]]', 'null')
                             .gsub('[[DOCBOOK_CONTENT]]', 'null')
                             .gsub('[[DOCBOOK_INDEX]]', 'null')
        else
          # single_file: embed everything inline via gsub placeholders
          docbook_json = DocumentData.new(title: output.title).to_json.gsub('</script>', '<\\/script>')
          toc_json = output.toc.to_json.gsub('</script>', '<\\/script>')
          content_json = output.content.to_json.gsub('</script>', '<\\/script>')
          index_json = output.index&.to_json&.gsub('</script>', '<\\/script>') || 'null'

          template = Liquid::Template.parse(template_content)
          rendered = template.render(
            "docbook_title" => output.title || "DocBook Document",
            "base_url" => base_url,
            "assets_inline" => true,
            "app_css" => File.read(File.join(FRONTEND_ROOT, "app.css")),
            "app_js" => File.read(File.join(FRONTEND_ROOT, "app.iife.js"))
          )

          rendered = rendered.gsub('[[DOCBOOK_DATA]]', docbook_json)
                             .gsub('[[DOCBOOK_TOC]]', toc_json)
                             .gsub('[[DOCBOOK_CONTENT]]', content_json)
                             .gsub('[[DOCBOOK_INDEX]]', index_json)
        end
      end

      private

      # ── Output Mode Helpers ──────────────────────────────────────────

      def base_url
        @output_mode == :directory ? "." : ""
      end

      # ── XRef Resolution (using pre-built resolver) ──────────────────

      def resolve_xref_text(xref)
        linkend = xref.linkend&.to_s
        return "" unless linkend
        @xref_resolver&.title_for(linkend) || linkend
      end

      # ── Section Data Collection ─────────────────────────────────────

      def collect_sections
        sections = []
        case @document
        when Docbook::Elements::Book
          each_attr(@document, :preface) do |pf|
            sections << SectionData.new(
              id: element_id(pf),
              title: best_title(pf) || "Preface",
              type: 'preface'
            )
          end
          each_attr(@document, :part) do |part|
            sections << SectionData.new(
              id: element_id(part),
              title: best_title(part) || "Part",
              type: 'part',
              children: collect_part_children(part)
            )
          end
          each_attr(@document, :chapter) do |ch|
            sections << SectionData.new(
              id: element_id(ch),
              title: best_title(ch) || "Chapter",
              type: 'chapter'
            )
          end
          each_attr(@document, :appendix) do |ap|
            sections << SectionData.new(
              id: element_id(ap),
              title: best_title(ap) || "Appendix",
              type: 'appendix',
              children: collect_appendix_children(ap)
            )
          end
          each_attr(@document, :glossary) do |g|
            sections << SectionData.new(
              id: element_id(g),
              title: best_title(g) || "Glossary",
              type: 'glossary'
            )
          end
          each_attr(@document, :bibliography) do |b|
            sections << SectionData.new(
              id: element_id(b),
              title: best_title(b) || "References",
              type: 'bibliography'
            )
          end
          each_attr(@document, :index) do |idx|
            sections << SectionData.new(
              id: element_id(idx),
              title: best_title(idx) || "Index",
              type: 'index'
            )
          end
        when Docbook::Elements::Article
          each_attr(@document, :section) do |s|
            sections << SectionData.new(
              id: element_id(s),
              title: best_title(s) || "Section",
              type: 'section',
              children: collect_section_children(s)
            )
          end
        when Docbook::Elements::Reference
          # Reference is a top-level element containing refentry children
          each_attr(@document, :refentry) do |re|
            sections << SectionData.new(
              id: element_id(re),
              title: best_title(re) || "Reference Entry",
              type: 'reference'
            )
          end
        end
        sections
      end

      def collect_part_children(part)
        children = []
        each_attr(part, :preface) do |pf|
          children << SectionData.new(
            id: element_id(pf),
            title: best_title(pf) || "Preface",
            type: 'preface',
            children: collect_appendix_children(pf)
          )
        end
        each_attr(part, :chapter) do |ch|
          children << SectionData.new(
            id: element_id(ch),
            title: best_title(ch) || "Chapter",
            type: 'chapter',
            children: collect_section_children(ch)
          )
        end
        each_attr(part, :reference) do |ref|
          children << SectionData.new(
            id: element_id(ref),
            title: best_title(ref) || "Reference",
            type: 'chapter'
          )
        end
        each_attr(part, :appendix) do |ap|
          children << SectionData.new(
            id: element_id(ap),
            title: best_title(ap) || "Appendix",
            type: 'appendix',
            children: collect_appendix_children(ap)
          )
        end
        each_attr(part, :glossary) do |g|
          children << SectionData.new(
            id: element_id(g),
            title: best_title(g) || "Glossary",
            type: 'glossary'
          )
        end
        each_attr(part, :bibliography) do |b|
          children << SectionData.new(
            id: element_id(b),
            title: best_title(b) || "References",
            type: 'bibliography'
          )
        end
        each_attr(part, :index) do |idx|
          children << SectionData.new(
            id: element_id(idx),
            title: best_title(idx) || "Index",
            type: 'index'
          )
        end
        children
      end

      def collect_appendix_children(appendix)
        children = []
        each_attr(appendix, :section) do |s|
          children << SectionData.new(
            id: element_id(s),
            title: best_title(s) || "Section",
            type: 'section',
            children: collect_section_children(s)
          )
        end
        children
      end

      def collect_section_children(parent)
        children = []
        each_attr(parent, :section) do |s|
          children << SectionData.new(
            id: element_id(s),
            title: best_title(s) || "Section",
            type: 'section',
            children: collect_section_children(s)
          )
        end
        children
      end

      # ── Numbering ──────────────────────────────────────────────────

      def build_numbering_map(sections)
        builder = NumberingBuilder.new
        part_index = 0

        sections.each do |sec|
          case sec.type
          when 'part'
            part_num = builder.next_part
            builder.set_number(sec.id, part_num)
            # Parts have chapters inside them - use same part_index for all children
            number_section_tree(sec.children, builder, part_index: part_index, section_scope: sec.id, parent_number: part_num)
            part_index += 1
          when 'chapter', 'reference'
            chapter_num = builder.next_chapter(part_index)
            builder.set_number(sec.id, chapter_num)
            # Number children sections scoped to this chapter, prefix with chapter number
            number_section_tree(sec.children, builder, chapter_id: sec.id, chapter_num: chapter_num, part_index: part_index, section_scope: sec.id, parent_number: chapter_num)
          when 'appendix'
            appendix_num = builder.next_appendix
            appendix_full = "Appendix #{appendix_num}"
            builder.set_number(sec.id, appendix_full)
            number_section_tree(sec.children, builder, part_index: part_index, section_scope: sec.id, parent_number: appendix_full)
          else
            # preface, glossary, bibliography, index - no numbering typically
            number_section_tree(sec.children, builder, part_index: part_index)
          end
        end

        builder.numbering
      end

      # Recursively number sections within a chapter
      # @param children [Array<SectionData>] child sections to number
      # @param builder [NumberingBuilder] numbering builder
      # @param chapter_id [String, nil] the chapter xml_id for section scope tracking
      # @param chapter_num [String, nil] the chapter number for prefixing sections
      # @param appendix_prefix [String, nil] the appendix prefix for sections (e.g., "Appendix A")
      # @param part_index [Integer] the part index for chapter numbering scope
      # @param section_scope [String] the xml_id of the parent section for numbering scope
      # @param parent_number [String, nil] the full number of the parent section for building hierarchical numbers
      def number_section_tree(children, builder, chapter_id: nil, chapter_num: nil, appendix_prefix: nil, part_index: 0, section_scope: nil, parent_number: nil)
        return if children.nil?
        children.each do |child|
          case child.type
          when 'section'
            # Scope numbering to this section's ID so siblings share a counter
            scope_id = section_scope || chapter_id || "root_#{part_index}"
            section_num = builder.next_section(scope_id)
            # Build full number from parent chain: chapter_num.parent_num.section_num
            # For appendix_prefix, strip "Appendix " to get just the letter for child numbering
            base_prefix = appendix_prefix ? appendix_prefix.sub(/\AAppendix\s*/, '') : nil
            prefix = base_prefix || parent_number || chapter_num
            full_num = prefix ? "#{prefix}.#{section_num}" : section_num
            builder.set_number(child.id, full_num)
            # Recurse for nested sections, passing this section as the new scope
            number_section_tree(child.children, builder,
              chapter_id: chapter_id, chapter_num: chapter_num, appendix_prefix: appendix_prefix,
              part_index: part_index, section_scope: child.id, parent_number: full_num)
          when 'chapter', 'reference'
            new_chapter_num = builder.next_chapter(part_index)
            builder.set_number(child.id, new_chapter_num)
            number_section_tree(child.children, builder, chapter_id: child.id, chapter_num: new_chapter_num, part_index: part_index, section_scope: child.id, parent_number: new_chapter_num)
          when 'appendix'
            appendix_num = builder.next_appendix
            appendix_full = "Appendix #{appendix_num}"
            builder.set_number(child.id, appendix_full)
            # Prefix appendix sections with "Appendix A.", "Appendix B.", etc.
            number_section_tree(child.children, builder, chapter_id: chapter_id, chapter_num: chapter_num, appendix_prefix: appendix_full, part_index: part_index, section_scope: child.id, parent_number: appendix_full)
          else
            # Other types (preface, glossary, etc.) - no numbering, just recurse
            number_section_tree(child.children, builder, chapter_id: chapter_id, chapter_num: chapter_num, appendix_prefix: appendix_prefix, part_index: part_index, section_scope: section_scope, parent_number: parent_number)
          end
        end
      end

      # ── Content Map Building ───────────────────────────────────────

      def build_content_map(sections, all_index_terms = [])
        content = {}

        unless sections.empty?
          collect_all_sections(sections).each do |sec|
            content[sec.id] = build_section_content_data(sec)
          end
        end

        if @document.is_a?(Docbook::Elements::Article) && sections.empty?
          content["article-content"] = build_article_content_data
        end

        # Generate index content if there are index elements
        if @document.respond_to?(:index)
          Array(@document.index).each do |idx|
            index_content = build_index_content(idx, all_index_terms)
            content[idx.xml_id || "index"] = index_content if index_content
          end
        end

        # Generate setindex content if present
        if @document.respond_to?(:setindex)
          Array(@document.setindex).each do |sidx|
            index_content = build_setindex_content(sidx, all_index_terms)
            content[sidx.xml_id || "setindex"] = index_content if index_content
          end
        end

        content
      end

      def build_index(all_index_terms)
        return Index.new(groups: []) if all_index_terms.empty?

        generator = IndexGenerator.new(all_index_terms, @xref_resolver)
        groups = generator.generate

        index = Index.new(title: "Index")
        groups.each do |group|
          index_group = IndexGroup.new(letter: group[:letter])
          group[:entries].each do |entry|
            index_group.entries << IndexTerm.new(
              primary: entry[:primary],
              secondary: entry[:secondary],
              tertiary: entry[:tertiary],
              section_id: entry[:section_id],
              section_title: entry[:section_title],
              sort_as: entry[:primary_sort],
              sees: entry[:sees],
              see_alsos: entry[:see_alsos]
            )
          end
          index.groups << index_group
        end
        index
      end

      def build_index_content(index_element, all_index_terms)
        return nil if all_index_terms.empty?

        index_type = index_element.type
        # Filter indexterms by type
        filtered_terms = all_index_terms.select { |t| t[:type] == index_type }

        return nil if filtered_terms.empty?

        generator = IndexGenerator.new(filtered_terms, @xref_resolver)
        index_data = generator.generate

        section_content = SectionContent.new(section_id: index_element.xml_id || "index")
        section_content.add_block(ContentBlock.new(
          type: :index_section,
          text: index_element.title&.content,
          children: index_data.map { |group| index_group_to_block(group) }
        ))
        section_content
      end

      def build_setindex_content(setindex_element, all_index_terms)
        generator = IndexGenerator.new(all_index_terms, @xref_resolver)
        index_data = generator.generate

        section_content = SectionContent.new(section_id: setindex_element.xml_id || "setindex")
        section_content.add_block(ContentBlock.new(
          type: :index_section,
          text: setindex_element.title&.content,
          children: index_data.map { |group| index_group_to_block(group) }
        ))
        section_content
      end

      def index_group_to_block(group)
        block = ContentBlock.new(type: :index_letter, text: group[:letter])
        block.children = group[:entries].map { |entry| index_entry_to_block(entry) }
        block
      end

      def index_entry_to_block(entry)
        block = ContentBlock.new(type: :index_entry)

        # Primary term
        primary = ContentBlock.new(type: :text, text: entry[:primary])
        block.children << primary

        # Section link
        if entry[:section_id] && entry[:section_title]
          link = ContentBlock.new(
            type: :index_reference,
            text: entry[:section_title],
            src: "##{entry[:section_id]}"
          )
          block.children << link
        end

        # See entries
        entry[:sees].each do |see|
          block.children << ContentBlock.new(
            type: :index_see,
            text: "see #{see}"
          )
        end

        # See also entries
        entry[:see_alsos].each do |see_also|
          block.children << ContentBlock.new(
            type: :index_see_also,
            text: "see also #{see_also}"
          )
        end

        block
      end

      def collect_all_sections(sections)
        result = []
        sections.each do |sec|
          result << sec
          result.concat(collect_all_sections(sec.children)) if sec.children && sec.children.any?
        end
        result
      end

      def build_section_content_data(sec)
        element = find_section_element(sec.id)
        return SectionContent.new(section_id: sec.id) unless element

        section_content = SectionContent.new(section_id: sec.id)
        # RefEntry has its content in refsection children, not from each_mixed_content
        if element.is_a?(Docbook::Elements::RefEntry)
          section_content.add_block(build_refentry_block(element))
        else
          build_element_content(element, section_content)
          # Also render any bibliolist children (not yielded by each_mixed_content)
          if element.respond_to?(:bibliolist)
            Array(element.bibliolist).each do |bl|
              Array(bl.bibliomixed).each do |bm|
                section_content.add_block(build_bibliomixed_block(bm))
              end
            end
          end
        end
        section_content
      end

      def build_article_content_data
        section_content = SectionContent.new(section_id: "article-content")
        build_element_content(@document, section_content)
        section_content
      end

      def build_element_content(element, section_content)
        # Use each_mixed_content to process elements in document order
        return unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          case node
          when String
            # Skip pure whitespace strings between elements
            next if node =~ /\A\s*\z/

          when Docbook::Elements::Para
            section_content.add_block(build_para_block(node))

          when Docbook::Elements::MediaObject
            process_mediaobject(node, section_content)

          when Docbook::Elements::ProgramListing
            code_text = build_code_content(node)
            next if code_text.to_s.strip.empty?
            section_content.add_block(ContentBlock.new(
              type: :code,
              text: code_text,
              language: node.language
            ))

          when Docbook::Elements::Screen
            code_text = build_code_content(node)
            next if code_text.to_s.strip.empty?
            section_content.add_block(ContentBlock.new(
              type: :code,
              text: code_text,
              language: node.language
            ))

          when Docbook::Elements::BlockQuote
            block = ContentBlock.new(type: :blockquote)
            if node.attribution
              block.text = node.attribution.content
            end
            node.each_mixed_content do |child|
              case child
              when Docbook::Elements::Para
                block.children << build_para_block(child)
              end
            end
            section_content.add_block(block)

          when Docbook::Elements::OrderedList
            section_content.add_block(build_ordered_list_block(node))

          when Docbook::Elements::ItemizedList
            section_content.add_block(build_itemized_list_block(node))

          when Docbook::Elements::VariableList
            section_content.add_block(build_variablelist_block(node))

          when Docbook::Elements::Note
            section_content.add_block(build_admonition_block(:note, node))
          when Docbook::Elements::Warning
            section_content.add_block(build_admonition_block(:warning, node))
          when Docbook::Elements::Caution
            section_content.add_block(build_admonition_block(:caution, node))
          when Docbook::Elements::Important
            section_content.add_block(build_admonition_block(:important, node))
          when Docbook::Elements::Tip
            section_content.add_block(build_admonition_block(:tip, node))
          when Docbook::Elements::Danger
            section_content.add_block(build_admonition_block(:danger, node))

          when Docbook::Elements::Figure
            process_figure(node, section_content)

          when Docbook::Elements::Example
            section_content.add_block(build_example_block(node))

          when Docbook::Elements::InformalFigure
            process_informalfigure(node, section_content)

          when Docbook::Elements::GlossEntry
            section_content.add_block(build_glossentry_block(node))

          when Docbook::Elements::Bibliomixed
            section_content.add_block(build_bibliomixed_block(node))

          when Docbook::Elements::Bibliomixed
            section_content.add_block(build_bibliomixed_block(node))

          when Docbook::Elements::IndexDiv
            block = ContentBlock.new(type: :index_section, text: node.title&.content)
            section_content.add_block(block)

          when Docbook::Elements::LiteralLayout
            if node.content
              section_content.add_block(ContentBlock.new(
                type: :code,
                text: node.content.to_s
              ))
            end

          when Docbook::Elements::Simplesect
            block = ContentBlock.new(type: :section)
            block.children ||= []
            if node.title
              block.children << ContentBlock.new(
                type: :heading,
                text: node.title.content.to_s
              )
            end
            ss_blocks = build_block_content_from_element(node)
            block.children.concat(ss_blocks)
            section_content.add_block(block)

          when Docbook::Elements::Section
            # Nested section - create nested content
            nested = SectionContent.new(section_id: element_id(node))
            build_element_content(node, nested)
            block = ContentBlock.new(type: :section, children: nested.blocks)
            section_content.add_block(block)

          when Docbook::Elements::RefEntry
            section_content.add_block(build_refentry_block(node))

          when Docbook::Elements::FormalPara
            # Formal para has title + para content
            if node.title
              block = ContentBlock.new(type: :paragraph)
              block.children ||= []
              block.children << ContentBlock.new(type: :strong, text: node.title.content.to_s)
              block.children.concat(build_inline_content(node))
              section_content.add_block(block)
            elsif node.para
              Array(node.para).each { |p| section_content.add_block(build_para_block(p)) }
            end

          else
            # Skip unknown node types
          end
        end
      end

      def process_mediaobject(mo, section_content)
        Array(mo.imageobject).each do |io|
          next unless io.imagedata
          fileref = io.imagedata.fileref
          src = fileref ? process_image(fileref) : ""
          alt = io.alt&.content
          section_content.add_block(ContentBlock.new(
            type: :image,
            src: src,
            alt: alt
          ))
        end
      end

      def process_figure(fig, section_content)
        fig_title = fig.title&.content
        Array(fig.mediaobject).each do |mo|
          mo_alt = mo.alt&.content if mo.respond_to?(:alt) && mo.alt
          Array(mo.imageobject).each do |io|
            next unless io.imagedata
            fileref = io.imagedata.fileref
            src = fileref ? process_image(fileref) : ""
            alt = mo_alt || io.alt&.content || fig_title
            section_content.add_block(ContentBlock.new(
              type: :image,
              src: src,
              alt: alt,
              title: fig_title
            ))
          end
          Array(mo.textobject).each do |to|
            # TextObject has content as a string, not nested para
            if to.content && !to.content.to_s.strip.empty?
              section_content.add_block(ContentBlock.new(
                type: :paragraph,
                text: to.content.to_s
              ))
            end
          end
        end
        Array(fig.programlisting).each do |pl|
          code_text = build_code_content(pl)
          section_content.add_block(ContentBlock.new(type: :code, text: code_text, language: pl.language)) unless code_text.to_s.strip.empty?
        end
        Array(fig.screen).each do |s|
          code_text = build_code_content(s)
          section_content.add_block(ContentBlock.new(type: :code, text: code_text, language: s.language)) unless code_text.to_s.strip.empty?
        end
      end

      def process_informalfigure(ifig, section_content)
        Array(ifig.mediaobject).each do |mo|
          Array(mo.imageobject).each do |io|
            next unless io.imagedata
            fileref = io.imagedata.fileref
            src = fileref ? process_image(fileref) : ""
            alt = io.alt&.content
            section_content.add_block(ContentBlock.new(
              type: :image,
              src: src,
              alt: alt
            ))
          end
        end
      end

      def build_ordered_list_block(ol)
        block = ContentBlock.new(type: :ordered_list)
        block.children ||= []
        Array(ol.listitem).each do |li|
          item = ContentBlock.new(type: :list_item)
          item.children ||= []
          li_blocks = build_block_content_from_element(li)
          item.children.concat(li_blocks)
          block.children << item
        end
        block
      end

      def build_itemized_list_block(ul)
        block = ContentBlock.new(type: :itemized_list)
        block.children ||= []
        Array(ul.listitem).each do |li|
          item = ContentBlock.new(type: :list_item)
          item.children ||= []
          li_blocks = build_block_content_from_element(li)
          item.children.concat(li_blocks)
          block.children << item
        end
        block
      end

      def build_variablelist_block(vl)
        vl_block = ContentBlock.new(type: :definition_list)
        vl_block.children ||= []
        Array(vl.varlistentry).each do |entry|
          # Term block - rendered in special style
          term_block = ContentBlock.new(type: :definition_term)
          term_block.children ||= []
          Array(entry.term).each do |t|
            term_content = build_inline_content_for_term(t)
            term_block.children << ContentBlock.new(type: :text, text: term_content)
          end
          vl_block.children << term_block

          # Definition description block - contains the listitem content
          if entry.listitem
            def_block = ContentBlock.new(type: :definition_description)
            def_block.children ||= []
            li_blocks = build_block_content_from_element(entry.listitem)
            def_block.children.concat(li_blocks)
            vl_block.children << def_block
          end
        end
        vl_block
      end

      def build_example_block(ex)
        block = ContentBlock.new(type: :example)
        block.children ||= []
        block.text = ex.title&.content
        ex.each_mixed_content do |child|
          case child
          when Docbook::Elements::Para
            block.children << build_para_block(child)
          when Docbook::Elements::ProgramListing
            code_text = build_code_content(child)
            block.children << ContentBlock.new(type: :code, text: code_text, language: child.language) unless code_text.to_s.strip.empty?
          when Docbook::Elements::Screen
            code_text = build_code_content(child)
            block.children << ContentBlock.new(type: :code, text: code_text, language: child.language) unless code_text.to_s.strip.empty?
          when Docbook::Elements::LiteralLayout
            block.children << ContentBlock.new(type: :code, text: child.content.to_s) if child.content
          when Docbook::Elements::Figure
            # Process figure within example
            fig_block = ContentBlock.new(type: :image)
            Array(child.mediaobject).each do |mo|
              Array(mo.imageobject).each do |io|
                next unless io.imagedata
                fig_block.src = process_image(io.imagedata.fileref)
                fig_block.alt = io.alt&.content
              end
            end
            block.children << fig_block
          end
        end
        block
      end

      def build_informalexample_block(element)
        block = ContentBlock.new(type: :example_output)
        block.children ||= []
        element.each_mixed_content do |child|
          case child
          when Docbook::Elements::Para
            block.children << build_para_block(child)
          when Docbook::Elements::ProgramListing
            code_text = build_code_content(child)
            block.children << ContentBlock.new(type: :code, text: code_text, language: child.language) unless code_text.to_s.strip.empty?
          when Docbook::Elements::Screen
            code_text = build_code_content(child)
            block.children << ContentBlock.new(type: :code, text: code_text, language: child.language) unless code_text.to_s.strip.empty?
          when Docbook::Elements::LiteralLayout
            block.children << ContentBlock.new(type: :code, text: child.content.to_s) if child.content
          end
        end
        block
      end

      def build_glossentry_block(entry)
        block = ContentBlock.new(type: :definition_list)
        block.children ||= []
        # Term
        term_block = ContentBlock.new(type: :definition_term)
        term_block.children ||= []
        if entry.glossterm
          term_text = entry.glossterm.content.to_s
          term_block.children << ContentBlock.new(type: :text, text: term_text)
        end
        block.children << term_block
        # Definition
        if entry.glossdef
          def_block = ContentBlock.new(type: :definition_description)
          def_block.children ||= []
          entry.glossdef.each_mixed_content do |child|
            case child
            when Docbook::Elements::Para
              def_block.children << build_para_block(child)
            end
          end
          block.children << def_block
        end
        block
      end

      def build_bibliomixed_block(bm)
        block = ContentBlock.new(type: :bibliography_entry)
        block.children ||= []

        # Abbrev
        if bm.abbrev&.content
          block.children << ContentBlock.new(type: :biblio_abbrev, text: bm.abbrev.content)
        end

        # Author with personname
        Array(bm.author).each do |author|
          if author.personname
            pn = author.personname
            first = pn.firstname&.content
            sur = pn.surname&.content
            name_text = [first, sur].compact.join(" ")
            if name_text.any?
              block.children << ContentBlock.new(type: :biblio_personname, text: name_text, class_name: "first-last personname")
            end
          end
        end

        # Personname (inline)
        Array(bm.personname).each do |pn|
          first = pn.firstname&.content
          sur = pn.surname&.content
          name_text = [first, sur].compact.join(" ")
          if name_text.any?
            block.children << ContentBlock.new(type: :biblio_personname, text: name_text, class_name: "first-last personname")
          end
        end

        # Firstname and surname separately
        if bm.firstname&.content
          block.children << ContentBlock.new(type: :biblio_firstname, text: bm.firstname.content, class_name: "firstname")
        end
        if bm.surname&.content
          block.children << ContentBlock.new(type: :biblio_surname, text: bm.surname.content, class_name: "surname")
        end

        # Citetitle
        Array(bm.citetitle).each do |ct|
          if ct.href
            block.children << ContentBlock.new(type: :link, text: ct.content, src: ct.href, class_name: "title")
          else
            block.children << ContentBlock.new(type: :biblio_citetitle, text: ct.content, class_name: "title")
          end
        end

        # Orgname
        Array(bm.orgname).each do |on|
          if on.content
            block.children << ContentBlock.new(type: :biblio_orgname, text: on.content, class_name: "orgname")
          end
        end

        # Publishername
        Array(bm.publishername).each do |pn|
          if pn.content
            block.children << ContentBlock.new(type: :biblio_publishername, text: pn.content, class_name: "publishername")
          end
        end

        # Pubdate
        if bm.pubdate
          block.children << ContentBlock.new(type: :biblio_pubdate, text: bm.pubdate.to_s, class_name: "pubdate")
        end

        # Links
        Array(bm.link).each do |lnk|
          block.children << ContentBlock.new(type: :link, text: lnk.content, src: lnk.href)
        end

        # Trailing text content
        trailing = bm.content.is_a?(Array) ? bm.content.join : bm.content.to_s
        block.children << ContentBlock.new(type: :text, text: trailing) if trailing

        block.text = block.children.map { |c| c.text || "" }.join(" ")
        block
      end

      def build_refentry_block(re)
        block = ContentBlock.new(type: :reference_entry)
        block.children ||= []

        # Determine the NAME of this entry (priority: refname > refentrytitle > fieldsynopsis.varname)
        entry_name = nil
        if re.refnamediv&.refname && re.refnamediv.refname.any?
          entry_name = re.refnamediv.refname.map { |n| n.content }.join(" ")
        elsif re.refmeta&.refentrytitle
          entry_name = re.refmeta.refentrytitle.content
        elsif re.refmeta&.respond_to?(:fieldsynopsis) && re.refmeta.fieldsynopsis
          # fieldsynopsis is a collection, find first with varname
          re.refmeta.fieldsynopsis.each do |fs|
            # fs.varname might be nil due to namespace issues, so try direct content access
            if fs.respond_to?(:varname) && fs.varname.is_a?(String) && !fs.varname.empty?
              entry_name = fs.varname
              break
            elsif fs.respond_to?(:content)
              # Fallback: extract varname from content using regex
              # Content might be an array or string containing "varname" followed by the actual value
              content_str = fs.content.is_a?(Array) ? fs.content.join(" ") : fs.content.to_s
              # Match "varname" followed by whitespace and the value
              varname_match = content_str.match(/varname\s+([^\n]+)/)
              if varname_match
                entry_name = varname_match[1].strip
                break
              end
            end
          end
        end

        # Fallback: use refpurpose as name if still no name found
        if entry_name.nil? && re.refnamediv&.refpurpose
          content = re.refnamediv.refpurpose.content
          # Handle both string and array content (mixed content from inline elements)
          purpose_text = if content.is_a?(Array)
            content.join("")
          elsif content.is_a?(String)
            content
          else
            content.to_s
          end
          # Truncate and clean up the purpose to use as a name
          entry_name = purpose_text.length > 50 ? purpose_text[0..47] + "..." : purpose_text
        end

        # Determine the BADGE (e.g., "pi" for processing instructions, "param" for template params)
        entry_badge = nil
        if re.refnamediv&.refclass
          entry_badge = re.refnamediv.refclass.content.to_s
        elsif entry_name&.start_with?("$")
          entry_badge = "param"
        end

        # Add badge first (top of entry)
        if entry_badge
          block.children << ContentBlock.new(
            type: :reference_badge,
            text: entry_badge
          )
        end

        # Add the NAME (headword)
        if entry_name
          block.children << ContentBlock.new(
            type: :reference_name,
            text: entry_name
          )
        end

        # Process refmeta refmiscinfo as metadata (only if not already captured as name)
        if re.refmeta
          if re.refmeta.respond_to?(:refmiscinfo) && re.refmeta.refmiscinfo
            re.refmeta.refmiscinfo.each do |info|
              block.children << ContentBlock.new(
                type: :reference_meta,
                text: info.content
              ) if info && info.content
            end
          end
          if re.refmeta.manvolnum
            block.children << ContentBlock.new(
              type: :reference_meta,
              text: "(#{re.refmeta.manvolnum})"
            )
          end
        end

        # Process refnamediv refpurpose - THE DEFINITION
        if re.refnamediv&.refpurpose
          content = re.refnamediv.refpurpose.content
          # Handle both string and array content (mixed content from inline elements)
          definition_text = if content.is_a?(Array)
            content.join("")
          elsif content.is_a?(String)
            content
          else
            content.to_s
          end
          block.children << ContentBlock.new(
            type: :reference_definition,
            text: definition_text
          )
        end

        # Process refsection sections (CONTENT of this entry)
        # NOTE: Skip rs.title - the entry_name already serves as the header
        Array(re.refsection).each do |rs|
          rs_block = ContentBlock.new(type: :description_section)
          rs_block.children ||= []
          # Don't add title - entry_name is the headword
          rs_block.children.concat(build_block_content_from_element(rs))
          block.children << rs_block
        end
        block
      end

      def build_admonition_block(type, element)
        block = ContentBlock.new(type: type, text: title_of(element))
        block.children ||= []
        each_attr(element, :para) { |p| block.children << build_para_block(p) }
        each_attr(element, :programlisting) do |pl|
          code_text = build_code_content(pl)
          block.children << ContentBlock.new(type: :code, text: code_text, language: pl.language) unless code_text.to_s.strip.empty?
        end
        each_attr(element, :screen) do |s|
          code_text = build_code_content(s)
          block.children << ContentBlock.new(type: :code, text: code_text, language: s.language) unless code_text.to_s.strip.empty?
        end
        each_attr(element, :literallayout) do |ll|
          block.children << ContentBlock.new(type: :code, text: ll.content.to_s) if ll.content
        end
        block
      end

      def build_para_block(p)
        block = ContentBlock.new(type: :paragraph)
        block.children = build_inline_content(p)
        block
      end

      # Build all block-level content from an element (used for listitems, simplesects, etc.)
      def build_block_content_from_element(element)
        blocks = []
        return blocks unless element.respond_to?(:each_mixed_content)

        element.each_mixed_content do |node|
          case node
          when String
            # Skip whitespace strings
            next if node =~ /\A\s*\z/
          when Docbook::Elements::Para
            blocks << build_para_block(node)
          when Docbook::Elements::LiteralLayout
            blocks << ContentBlock.new(type: :code, text: node.content.to_s) if node.content
          when Docbook::Elements::ProgramListing
            code_text = build_code_content(node)
            blocks << ContentBlock.new(type: :code, text: code_text, language: node.language) unless code_text.to_s.strip.empty?
          when Docbook::Elements::Screen
            code_text = build_code_content(node)
            blocks << ContentBlock.new(type: :code, text: code_text, language: node.language) unless code_text.to_s.strip.empty?
          when Docbook::Elements::Simplesect
            block = ContentBlock.new(type: :section)
            block.children ||= []
            if node.title
              block.children << ContentBlock.new(type: :heading, text: node.title.content.to_s)
            end
            ss_blocks = build_block_content_from_element(node)
            block.children.concat(ss_blocks)
            blocks << block
          when Docbook::Elements::VariableList
            blocks << build_variablelist_block(node)
          when Docbook::Elements::InformalExample
            blocks << build_informalexample_block(node)
          end
        end
        blocks
      end

      # Build inline content (children) from element using each_mixed_content
      # This yields proper model objects (not XML elements) in document order
      def build_inline_content(element)
        children = []
        element.each_mixed_content do |node|
          case node
          when String
            children << ContentBlock.new(type: :text, text: node) if node&.strip&.then { !_1.empty? }
          when Docbook::Elements::Emphasis
            children << build_emphasis_block(node)
          when Docbook::Elements::Link
            children << build_link_block(node)
          when Docbook::Elements::Xref
            children << build_xref_block(node)
          when Docbook::Elements::Code, Docbook::Elements::Literal
            children << ContentBlock.new(type: :codetext, text: extract_text_content(node))
          when Docbook::Elements::Filename, Docbook::Elements::ProductName,
               Docbook::Elements::ClassName, Docbook::Elements::Function,
               Docbook::Elements::Parameter, Docbook::Elements::BuildTarget,
               Docbook::Elements::Dir, Docbook::Elements::Replaceable
            children << ContentBlock.new(type: :codetext, text: node.content)
          when Docbook::Elements::Quote
            # Handle quote with nested replaceable
            if Array(node.replaceable).any?
              text = node.replaceable.map(&:content).join("")
              children << ContentBlock.new(type: :text, text: "\"#{text}\"")
            else
              children << ContentBlock.new(type: :text, text: "\"#{node.content}\"")
            end
          when Docbook::Elements::UserInput, Docbook::Elements::Screen
            children << ContentBlock.new(type: :codetext, text: node.content)
          when Docbook::Elements::Citetitle
            if node.href
              children << ContentBlock.new(type: :citation_link, text: node.content, src: node.href.to_s)
            else
              children << ContentBlock.new(type: :citation, text: node.content)
            end
          when Docbook::Elements::Biblioref
            # Use linkend as display text since biblioref is often self-closing
            text = node.content.to_s.empty? ? node.linkend : node.content
            children << ContentBlock.new(type: :biblioref, text: text, src: "##{node.linkend}")
          when Docbook::Elements::FirstTerm, Docbook::Elements::Glossterm
            children << ContentBlock.new(type: :emphasis, text: extract_text_content(node))
          when Docbook::Elements::Tag
            # Render tag elements like <appendix> as inline code text
            tag_content = node.content.to_s
            children << ContentBlock.new(type: :codetext, text: "<#{tag_content}>")
          when Docbook::Elements::Att
            children << ContentBlock.new(type: :codetext, text: node.content.to_s)
          when Docbook::Elements::Inlinemediaobject
            children << build_inline_image_block(node)
          else
            # Generic fallback for any other Serializable
            children << ContentBlock.new(type: :text, text: node.content.to_s) if node.content
          end
        end
        children
      end

      def build_emphasis_block(el)
        type = case el.role
               when "bold", "strong" then :strong
               when "italic" then :italic
               else :emphasis
               end
        ContentBlock.new(type: type, text: el.content)
      end

      def build_link_block(el)
        href = if el.xlink_href
                 el.xlink_href.to_s
               elsif el.linkend
                 "##{el.linkend}"
               else
                 "#"
               end
        text = el.content
        text = href if text.nil? || text.strip.empty?
        ContentBlock.new(type: :link, text: text, src: href)
      end

      def build_xref_block(el)
        href = el.linkend ? "##{el.linkend}" : "#"
        text = resolve_xref_text(el)
        text ||= el.content.to_s if el.content
        ContentBlock.new(type: :xref, text: text || href, src: href)
      end

      def build_inline_image_block(el)
        if el.imageobject&.imagedata&.fileref
          src = process_image(el.imageobject.imagedata.fileref)
          alt = el.alt&.content
          ContentBlock.new(type: :inline_image, src: src, alt: alt)
        else
          ContentBlock.new(type: :text, text: "[image]")
        end
      end

      # Extract text content from an element, using each_mixed_content
      # to handle CDATA sections that don't get mapped to .content
      def extract_text_content(el)
        if el.respond_to?(:each_mixed_content) && (el.content.nil? || el.content.to_s.empty?)
          text = []
          el.each_mixed_content { |n| text << n.to_s if n.is_a?(String) }
          return text.join unless text.empty?
        end
        el.content.to_s
      end

      # Build text content from a screen/programlisting element, handling mixed content
      # Returns the concatenated text content
      def build_code_content(el)
        return el.content.to_s unless el.respond_to?(:each_mixed_content)

        result = []
        el.each_mixed_content do |node|
          case node
          when String
            result << node
          when Docbook::Elements::UserInput, Docbook::Elements::ComputerOutput,
               Docbook::Elements::Code, Docbook::Elements::Literal
            result << node.content.to_s
          when Docbook::Elements::Emphasis
            result << node.content.to_s
          when Docbook::Elements::Filename, Docbook::Elements::ProductName
            result << node.content.to_s
          when Docbook::Elements::Link
            result << node.content.to_s
          when Docbook::Elements::Xref
            result << node.content.to_s
          when Docbook::Elements::Tag
            result << "<#{node.content}>"
          when Docbook::Elements::Att
            result << node.content.to_s
          else
            result << node.content.to_s if node.respond_to?(:content) && node.content
          end
        end
        result.join("")
      end

      # Build text content from a term element, handling mixed content
      # Uses each_mixed_content since Term now has typed inline elements
      def build_inline_content_for_term(term_el)
        return "" unless term_el.respond_to?(:each_mixed_content)

        result = []
        term_el.each_mixed_content do |node|
          case node
          when String
            result << node if node&.strip&.then { !_1.empty? }
          when Docbook::Elements::Code, Docbook::Elements::Literal
            result << node.content.to_s
          when Docbook::Elements::Emphasis
            result << node.content.to_s
          when Docbook::Elements::Filename, Docbook::Elements::ProductName
            result << node.content.to_s
          when Docbook::Elements::Link
            result << node.content.to_s
          when Docbook::Elements::Xref
            result << node.content.to_s
          when Docbook::Elements::Tag
            result << "<#{node.content}>"
          when Docbook::Elements::Att
            result << node.content.to_s
          when Docbook::Elements::Property
            result << node.content.to_s
          end
        end
        result.join("")
      end

      def find_section_element(id)
        return find_in_document_fallback(id) unless @xref_resolver
        @xref_resolver[id] || find_in_document_fallback(id)
      end

      def find_in_document_fallback(id)
        find_in_document(@document, id)
      end

      # Recursively search for element with matching id using typed collections
      def find_in_document(el, id)
        return el if element_id(el) == id

        case el
        when Docbook::Elements::Book
          [
            el.part, el.chapter, el.appendix, el.preface,
            el.glossary, el.bibliography, el.index
          ].each do |children|
            Array(children).each do |child|
              result = find_in_document(child, id)
              return result if result
            end
          end
        when Docbook::Elements::Part
          [
            el.chapter, el.appendix, el.reference, el.preface,
            el.glossary, el.bibliography, el.index
          ].each do |children|
            Array(children).each do |child|
              result = find_in_document(child, id)
              return result if result
            end
          end
        when Docbook::Elements::Article
          Array(el.section).each do |child|
            result = find_in_document(child, id)
            return result if result
          end
        when Docbook::Elements::Chapter, Docbook::Elements::Appendix,
             Docbook::Elements::Section, Docbook::Elements::Preface
          Array(el.section).each do |child|
            result = find_in_document(child, id)
            return result if result
          end
        when Docbook::Elements::Reference
          Array(el.refentry).each do |child|
            result = find_in_document(child, id)
            return result if result
          end
        end

        nil
      end

      # ── Image Processing ────────────────────────────────────────────

      def process_image(fileref)
        return fileref unless @base_path

        if @output_mode == :single_file
          embed_image_base64(fileref)
        else
          find_file_path(fileref) || fileref
        end
      end

      # Find the actual file path by searching in base_path and parent directories
      # This handles cases where media/ is at a different level than xml/
      # Also tries prepending common prefixes like 'resources/' when direct path not found
      def find_file_path(fileref)
        # Try variations of the path with common prefixes
        path_prefixes = ["", "resources/", "../resources/"]
        search_paths = []

        # Build search paths: base_path and all parents
        path = @base_path
        loop do
          search_paths << path
          parent = File.dirname(path)
          break if parent == path
          path = parent
        end

        # For each search path, try with and without resource prefixes
        search_paths.each do |base|
          path_prefixes.each do |prefix|
            full_path = File.join(base, prefix, fileref)
            return full_path if File.exist?(full_path)
          end
        end
        nil
      end

      def embed_image_base64(fileref)
        return @image_cache[fileref] if @image_cache[fileref]

        full_path = find_file_path(fileref)
        return fileref unless full_path && File.exist?(full_path)

        data = File.binread(full_path)
        mime = Marcel::MimeType.for(data)
        encoded = Base64.strict_encode64(data)
        @image_cache[fileref] = "data:#{mime};base64,#{encoded}"
      end

      # ── Utility ─────────────────────────────────────────────────────

      def escape(text)
        return "" if text.nil?
        ERB::Util.html_escape(text.to_s)
      end

      def each_attr(obj, name)
        val = obj.send(name)
        return unless val
        Array(val).each { |item| yield item }
      rescue NoMethodError
        nil
      end

      # Get title content from element - elements with title attribute
      def title_of(el)
        case el
        when Docbook::Elements::Article, Docbook::Elements::Book
          el.info&.title&.content
        when Docbook::Elements::Section, Docbook::Elements::Chapter, Docbook::Elements::Appendix,
             Docbook::Elements::Preface, Docbook::Elements::Part, Docbook::Elements::Reference
          # These elements may have title inside info or as direct child
          el.info&.title&.content || el.title&.content
        when Docbook::Elements::RefEntry
          # RefEntry title is in refnamediv.refname, not in title element
          el.refnamediv&.refname&.first&.content
        when Docbook::Elements::Note, Docbook::Elements::Warning, Docbook::Elements::Caution,
             Docbook::Elements::Important, Docbook::Elements::Tip, Docbook::Elements::Danger
          el.title&.content
        when Docbook::Elements::BlockQuote, Docbook::Elements::Figure, Docbook::Elements::Example,
             Docbook::Elements::Equation
          el.title&.content
        else
          el.title&.content rescue nil
        end
      end

      def best_title(el)
        title_of(el)
      end

      def element_id(el)
        el.xml_id || begin
          t = best_title(el)
          t&.downcase&.gsub(/[^a-z0-9]+/, "-")&.gsub(/^-|-$/, "") || "el-#{el.object_id}"
        end
      end

      # ── Title Extraction ─────────────────────────────────────────────

      def extract_title
        case @document
        when Docbook::Elements::Book, Docbook::Elements::Article
          best_title(@document) || "DocBook"
        when Docbook::Elements::Section, Docbook::Elements::Preface,
             Docbook::Elements::Chapter, Docbook::Elements::Appendix
          best_title(@document) || "DocBook"
        else
          "DocBook"
        end
      end
    end
  end
end
