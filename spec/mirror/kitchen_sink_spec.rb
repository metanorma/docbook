# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Kitchen Sink Fixture — Full Pipeline", :mirror do
  let(:fixture_path) { File.expand_path("../fixtures/kitchen-sink/kitchen-sink.xml", __dir__) }
  let(:doc) { Docbook::Document.from_xml(File.read(fixture_path)) }
  let(:transformer) { Docbook::Mirror::Transformer.new }
  let(:result) { transformer.send(:from_docbook, doc).to_h }

  it "parses without errors" do
    expect(result["type"]).to eq("doc")
    expect(result["content"]).not_to be_empty
  end

  it "contains chapters" do
    chapters = collect_nodes(result, "chapter")
    expect(chapters.length).to be >= 3
  end

  it "contains chapter-level content nodes" do
    chapters = collect_nodes(result, "chapter")
    expect(chapters.length).to be >= 3
    # Verify chapters contain paragraphs
    paras_in_chapters = chapters.sum { |ch| collect_nodes(ch, "paragraph").length }
    expect(paras_in_chapters).to be >= 5
  end

  it "contains paragraphs with inline marks" do
    paras = collect_nodes(result, "paragraph")
    expect(paras.length).to be >= 10
  end

  it "contains code blocks" do
    code_blocks = collect_nodes(result, "code_block")
    expect(code_blocks.length).to be >= 3
  end

  it "contains lists" do
    ordered = collect_nodes(result, "ordered_list")
    bullet = collect_nodes(result, "bullet_list")
    dl = collect_nodes(result, "dl")
    expect(ordered.length).to be >= 1
    expect(bullet.length).to be >= 1
    expect(dl.length).to be >= 1
  end

  it "contains admonitions" do
    admonitions = collect_nodes(result, "admonition")
    expect(admonitions.length).to be >= 5
  end

  it "contains backmatter elements" do
    glossary = find_node(result, "glossary")
    bib = find_node(result, "bibliography")
    idx = find_node(result, "index_block")
    expect(glossary).not_to be_nil
    expect(bib).not_to be_nil
    expect(idx).not_to be_nil
  end

  it "generates valid TOC" do
    toc = Docbook::Services::TocGenerator.new(doc).generate
    expect(toc.length).to be >= 3
    titles = toc.map(&:title)
    expect(titles).to include("Block Elements")
    expect(titles).to include("Cross-References and Inline Elements")
  end

  it "generates document stats" do
    stats = Docbook::Services::DocumentStats.new(doc).generate
    expect(stats["title"]).to eq("Kitchen Sink Test Document")
    expect(stats["subtitle"]).to eq("Testing Every DocBook Element")
    expect(stats["author"]).to include("Jane Doe")
    expect(stats["author"]).to include("John Smith")
    expect(stats["pubdate"]).to eq("2026-01-15")
    expect(stats["copyright"]).to include("Test Holder")
  end
end
