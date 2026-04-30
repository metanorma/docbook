# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe "Ruby/JS rendering contract" do
  # ── Contract data ─────────────────────────────────────────────────
  # This mirrors frontend/src/types/rendering-contract.ts BLOCK_TYPES.
  # When adding a new block type, update BOTH this spec and the TS file.

  CONTRACT_BLOCK_TYPES = %w[
    paragraph blockquote synopsis
    code_block
    admonition
    image
    table
    ordered_list bullet_list dl
    step substeps
    calloutlist callout
    qandaset qandaentry question answer
    gloss_entry gloss_term gloss_def gloss_see gloss_see_also
    biblio_entry
    index_div index_entry
    footnotes
    annotation
    equation
    sidebar
    refsection
  ].freeze

  CONTRACT_SECTION_TYPES = %w[
    chapter section appendix part preface dedication
    acknowledgements colophon reference refentry
    glossary bibliography index_block procedure
    article topic set
  ].freeze

  CONTRACT_MARK_TYPES = %w[
    emphasis strong italic code link xref citation
    tag subscript superscript
  ].freeze

  CONTRACT_ADMONITION_TYPES = %w[
    note warning tip caution important danger
  ].freeze

  # ── Ruby HtmlRenderer coverage ────────────────────────────────────

  describe "HtmlRenderer handles all contract block types" do
    let(:renderer) { Docbook::Output::HtmlRenderer.new("content" => []) }

    it "has a render method for every block type in the contract" do
      missing = CONTRACT_BLOCK_TYPES.reject do |type|
        renderer.respond_to?(:"render_#{type}", true)
      end

      expect(missing).to be_empty,
        "HtmlRenderer missing render methods for: #{missing.join(', ')}. " \
        "Add render_#{missing.first} or update the contract."
    end

    it "does not have render methods for types not in the contract" do
      methods = renderer.private_methods(false).select { |m| m.to_s.start_with?("render_") }
        .map { |m| m.to_s.sub("render_", "") }

      # These are structural/helper renderers, not block types
      allowed_extra = %w[doc generic node children inline text_node
                         section_like table_section soft_break
                         glossary bibliography index_block procedure]

      extra = methods - CONTRACT_BLOCK_TYPES - CONTRACT_SECTION_TYPES - allowed_extra
      expect(extra).to be_empty,
        "HtmlRenderer has render methods for unregistered types: #{extra.join(', ')}. " \
        "Either add them to the contract or remove the methods."
    end
  end

  describe "HtmlRenderer handles all contract section types" do
    let(:renderer) { Docbook::Output::HtmlRenderer.new("content" => []) }

    it "has a render method for every section type" do
      missing = CONTRACT_SECTION_TYPES.reject do |type|
        renderer.respond_to?(:"render_#{type}", true)
      end

      expect(missing).to be_empty,
        "HtmlRenderer missing render methods for section types: #{missing.join(', ')}"
    end
  end

  # ── Admonition types ──────────────────────────────────────────────

  describe "admonition type coverage" do
    let(:renderer) { Docbook::Output::HtmlRenderer.new("content" => []) }

    it "defines titles for all contract admonition types" do
      titles = Docbook::Output::HtmlRenderer::ADMONITION_TITLES

      missing = CONTRACT_ADMONITION_TYPES.reject { |t| titles.key?(t) }
      expect(missing).to be_empty,
        "ADMONITION_TITLES missing entries for: #{missing.join(', ')}"
    end

    it "does not define extra admonition types beyond the contract" do
      titles = Docbook::Output::HtmlRenderer::ADMONITION_TITLES
      extra = titles.keys - CONTRACT_ADMONITION_TYPES
      expect(extra).to be_empty,
        "ADMONITION_TITLES has extra types: #{extra.join(', ')}. Update the contract."
    end
  end

  # ── CSS class consistency ─────────────────────────────────────────

  describe "CSS class output" do
    let(:guide) { { "content" => [] } }
    let(:renderer) { Docbook::Output::HtmlRenderer.new(guide) }

    it "uses db-paragraph class for paragraphs" do
      node = { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "hi" }] }
      html = renderer.send(:render_paragraph, node)
      expect(html).to include('class="db-paragraph"')
    end

    it "uses db-code-block class for code blocks" do
      node = { "type" => "code_block", "attrs" => { "text" => "code" } }
      html = renderer.send(:render_code_block, node)
      expect(html).to include('class="db-code-block"')
    end

    it "uses db-admonition with type modifier" do
      CONTRACT_ADMONITION_TYPES.each do |atype|
        node = { "type" => "admonition", "attrs" => { "admonition_type" => atype }, "content" => [] }
        html = renderer.send(:render_admonition, node)
        expect(html).to include("db-admonition db-admonition--#{atype}")
      end
    end

    it "uses db-table class for tables" do
      node = { "type" => "table", "content" => [] }
      html = renderer.send(:render_table, node)
      expect(html).to include('class="db-table"')
    end

    it "uses db-blockquote class for blockquotes" do
      node = { "type" => "blockquote", "content" => [] }
      html = renderer.send(:render_blockquote, node)
      expect(html).to include('class="db-blockquote"')
    end

    it "uses db-sidebar class for sidebars" do
      node = { "type" => "sidebar", "attrs" => {}, "content" => [] }
      html = renderer.send(:render_sidebar, node)
      expect(html).to include('class="db-sidebar"')
    end

    it "uses db-equation class for equations" do
      node = { "type" => "equation", "attrs" => {}, "content" => [] }
      html = renderer.send(:render_equation, node)
      expect(html).to include('class="db-equation"')
    end
  end

  # ── Inline mark coverage ──────────────────────────────────────────

  describe "inline mark types" do
    let(:renderer) { Docbook::Output::HtmlRenderer.new("content" => []) }

    it "apply_mark handles all contract mark types" do
      CONTRACT_MARK_TYPES.each do |mark_type|
        mark = { "type" => mark_type }
        mark["attrs"] = { "href" => "#" } if mark_type == "link"
        mark["attrs"] = { "linkend" => "x" } if mark_type == "xref"
        mark["attrs"] = { "bibref" => "ref" } if mark_type == "citation"
        mark["attrs"] = { "role" => "literal" } if mark_type == "code"

        result = renderer.send(:apply_mark, "text", mark)
        expect(result).not_to eq("text"),
          "apply_mark for '#{mark_type}' returned unmodified text (unhandled mark type)"
      end
    end
  end
end
