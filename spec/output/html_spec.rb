# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Docbook::Output::Html do
  let(:sample_xml) { File.read("spec/fixtures/xslTNG/guide/xml/examples/sample.xml") }

  describe "#to_html" do
    it "generates valid HTML" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("<html lang=\"en\"")
      expect(html).to include("</html>")
    end

    it "includes Vue.js bundle" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      expect(html).to include("DOCBOOK_DATA")
      expect(html).to include("docbook-app")
    end

    it "includes Google Fonts" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      expect(html).to include("fonts.googleapis.com")
      expect(html).to include("Inter")
      expect(html).to include("Merriweather")
      expect(html).to include("JetBrains+Mono")
    end

    it "includes dark mode toggle" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      expect(html).to include("Night")
      expect(html).to include("Day")
      expect(html).to include("Sepia")
      expect(html).to include("OLED")
    end

    it "renders article title in DOCBOOK_DATA" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      expect(docbook_data["title"]).to include("Sample Document")
    end

    it "renders paragraphs in content map" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      expect(docbook_data["content"]).to be_a(Hash)
      section_content = docbook_data["content"]["article-content"]
      expect(section_content["blocks"]).to be_an(Array)
      # Check paragraph text
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      para_text = para["children"].map { |c| c["text"] || "" }.join
      expect(para_text).to include("This is a sample")
    end

    it "renders inline elements in content map" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      section_content = docbook_data["content"]["article-content"]
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      children_text = para["children"].map { |c| c["text"] || "" }.join
      expect(children_text).to include("This is a sample")
      expect(children_text).to include("DocBook")
    end

    it "renders emphasis with role=bold as strong" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
        <para>Hello <emphasis role="bold">world</emphasis></para>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      section_content = docbook_data["content"]["article-content"]
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      # Should have a strong child
      strong_child = para["children"].find { |c| c["type"] == "strong" }
      expect(strong_child).not_to be_nil
      expect(strong_child["text"]).to include("world")
    end

    it "renders emphasis without role as italic" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
        <para>Hello <emphasis>world</emphasis></para>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      section_content = docbook_data["content"]["article-content"]
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      # Should have an italic or emphasis child
      italic_child = para["children"].find { |c| c["type"] == "italic" || c["type"] == "emphasis" }
      expect(italic_child).not_to be_nil
      expect(italic_child["text"]).to include("world")
    end

    it "renders link with xlink:href" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
        <para><link xlink:href="https://example.com">click here</link></para>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      section_content = docbook_data["content"]["article-content"]
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      # Should have a link child with src and text
      link_child = para["children"].find { |c| c["type"] == "link" }
      expect(link_child).not_to be_nil
      expect(link_child["src"]).to include("https://example.com")
      expect(link_child["text"]).to include("click here")
    end

    it "escapes HTML in content" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
        <para>Use &lt;html&gt; tags</para>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      section_content = docbook_data["content"]["article-content"]
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      # Text content should have the literal <html> (escaped when rendered)
      para_text = para["children"].map { |c| c["text"] || "" }.join
      expect(para_text).to include("Use <html> tags")
    end

    it "renders code elements" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
        <para>Use <code>puts</code> to print</para>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      section_content = docbook_data["content"]["article-content"]
      para = section_content["blocks"].find { |b| b["type"] == "paragraph" }
      expect(para).not_to be_nil
      # Should have a codetext child
      code_child = para["children"].find { |c| c["type"] == "codetext" }
      expect(code_child).not_to be_nil
      expect(code_child["text"]).to include("puts")
    end

    it "renders book with parts and chapters" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.1">
        <info><title>Test Book</title></info>
        <part><title>Part One</title>
          <chapter><title>Chapter One</title><para>Content</para></chapter>
        </part>
        </book>
      XML
      book = Docbook::Elements::Book.from_xml(xml)
      html = described_class.new(book).to_html
      docbook_data = extract_docbook_data(html)
      expect(docbook_data["title"]).to include("Test Book")
      # Part is at top level
      expect(docbook_data["sections"].map { |s| s["title"] }).to include("Part One")
      # Chapter is nested inside Part's children
      part = docbook_data["sections"].find { |s| s["title"] == "Part One" }
      expect(part["children"].map { |c| c["title"] }).to include("Chapter One")
    end

    it "includes Metanorma Docbook gem attribution" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      expect(html).to include("Generated by")
      expect(html).to include("metanorma-docbook")
    end

    it "includes TOC data with sections" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
        <section><title>Getting Started</title><para>Content</para></section>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      html = described_class.new(article).to_html
      docbook_data = extract_docbook_data(html)
      expect(docbook_data["sections"].map { |s| s["title"] }).to include("Getting Started")
    end

    it "renders bibliography" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.1">
        <info><title>Test Book</title></info>
        <bibliography><title>References</title>
          <bibliomixed><abbrev>Ref1</abbrev> A reference</bibliomixed>
        </bibliography>
        </book>
      XML
      book = Docbook::Elements::Book.from_xml(xml)
      html = described_class.new(book).to_html
      docbook_data = extract_docbook_data(html)
      expect(docbook_data["sections"].map { |s| s["title"] }).to include("References")
    end

    it "renders chapter numbering" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.1">
        <info><title>Test Book</title></info>
        <chapter><title>First</title><para>Content</para></chapter>
        <chapter><title>Second</title><para>Content</para></chapter>
        </book>
      XML
      book = Docbook::Elements::Book.from_xml(xml)
      html = described_class.new(book).to_html
      docbook_data = extract_docbook_data(html)
      expect(docbook_data["numbering"]).to be_a(Hash)
      expect(docbook_data["numbering"]).not_to be_empty
    end

    it "renders appendix with distinct styling" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.1">
        <info><title>Test Book</title></info>
        <appendix><title>License</title><para>Content</para></appendix>
        </book>
      XML
      book = Docbook::Elements::Book.from_xml(xml)
      html = described_class.new(book).to_html
      docbook_data = extract_docbook_data(html)
      # Appendix section should exist
      appendix_section = docbook_data["sections"].find { |s| s["type"] == "appendix" }
      expect(appendix_section).not_to be_nil
    end

    it "includes FlexSearch" do
      article = Docbook::Elements::Article.from_xml(sample_xml)
      html = described_class.new(article).to_html
      # FlexSearch is in the minified Vue bundle as FlexSearch
      expect(html).to include("FlexSearch")
    end
  end

  def extract_docbook_data(html)
    # Match Object.assign(docbook_json, {toc: toc_json, content: content_json, index: index_json})
    match = html.match(/window\.DOCBOOK_DATA\s*=\s*Object\.assign\((.+?),\s*\{\s*toc:\s*(.+?),\s*content:\s*(.+?),\s*index:\s*(.+?)\s*\}\s*\)/m)
    return {} unless match

    data = JSON.parse(match[1])
    toc_raw = JSON.parse(match[2])
    content_raw = JSON.parse(match[3])
    index_raw = match[4].strip == 'null' ? nil : JSON.parse(match[4])

    # Toc: extract sections and convert numbering entries to map
    data["sections"] = toc_raw["sections"] || []
    numbering_raw = toc_raw["numbering"]
    if numbering_raw.is_a?(Array)
      # NumberingEntry collection serializes as direct array
      data["numbering"] = numbering_raw.each_with_object({}) { |e, m| m[e["id"]] = e["value"] }
    elsif numbering_raw.is_a?(Hash) && numbering_raw["entries"].is_a?(Array)
      data["numbering"] = numbering_raw["entries"].each_with_object({}) { |e, m| m[e["id"]] = e["value"] }
    else
      data["numbering"] = numbering_raw || {}
    end

    # Content: convert entries array to map
    if content_raw.is_a?(Hash) && content_raw["entries"].is_a?(Array)
      data["content"] = content_raw["entries"].each_with_object({}) { |e, m| m[e["key"]] = e["value"] }
    else
      data["content"] = {}
    end

    # Index: keep as-is
    data["index"] = index_raw

    data
  rescue JSON::ParserError
    {}
  end
end
