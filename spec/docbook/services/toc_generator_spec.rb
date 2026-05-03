# frozen_string_literal: true

RSpec.describe Docbook::Services::TocGenerator do
  describe "#generate" do
    it "generates TOC from book with chapters" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Test Book</title>
          <chapter xml:id="ch1"><title>Chapter 1</title><para>Text</para></chapter>
          <chapter xml:id="ch2"><title>Chapter 2</title><para>Text</para></chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      toc = described_class.new(doc).generate

      expect(toc.size).to eq(2)
      expect(toc[0].title).to eq("Chapter 1")
      expect(toc[0].id).to eq("ch1")
      expect(toc[1].title).to eq("Chapter 2")
    end

    it "generates nested TOC for sections" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter xml:id="ch1">
            <title>Chapter</title>
            <section xml:id="s1"><title>Section 1</title><para>Text</para></section>
            <section xml:id="s2"><title>Section 2</title><para>Text</para></section>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      toc = described_class.new(doc).generate

      expect(toc.size).to eq(1)
      expect(toc[0].children.size).to eq(2)
      expect(toc[0].children[0].title).to eq("Section 1")
    end

    it "generates TOC for article with sections" do
      xml = <<~XML
        <article xmlns="http://docbook.org/ns/docbook">
          <title>Article</title>
          <section xml:id="s1"><title>First</title><para>Text</para></section>
        </article>
      XML
      doc = Docbook::Document.from_xml(xml)
      toc = described_class.new(doc).generate

      expect(toc.size).to eq(1)
      expect(toc[0].id).to eq("s1")
    end

    it "generates TOC with appendix and glossary" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <chapter xml:id="ch1"><title>Chapter</title><para>Text</para></chapter>
          <appendix xml:id="app1"><title>Appendix A</title><para>Text</para></appendix>
          <glossary xml:id="gloss"><title>Glossary</title></glossary>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      toc = described_class.new(doc).generate

      types = toc.map(&:type)
      expect(types).to include("chapter", "appendix", "glossary")
    end

    it "uses Untitled for elements without titles" do
      xml = <<~XML
        <article xmlns="http://docbook.org/ns/docbook">
          <section xml:id="notitle"><para>No title</para></section>
        </article>
      XML
      doc = Docbook::Document.from_xml(xml)
      toc = described_class.new(doc).generate

      expect(toc[0].title).to eq("Untitled")
    end
  end
end
