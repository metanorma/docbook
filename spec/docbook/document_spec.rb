# frozen_string_literal: true

RSpec.describe Docbook::Document do
  describe ".from_xml" do
    it "parses a book" do
      xml = '<book xmlns="http://docbook.org/ns/docbook"><title>Test</title></book>'
      doc = described_class.from_xml(xml)
      expect(doc).to be_a(Docbook::Elements::Book)
    end

    it "parses an article" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Text</para></article>'
      doc = described_class.from_xml(xml)
      expect(doc).to be_a(Docbook::Elements::Article)
    end

    it "raises on unsupported root element" do
      expect do
        described_class.from_xml("<html></html>")
      end.to raise_error(Docbook::Error,
                         /Unsupported/)
    end

    it "raises on empty input" do
      expect do
        described_class.from_xml("")
      end.to raise_error(Docbook::Error, /Empty/)
    end
  end

  describe ".supports?" do
    it "returns true for known root elements" do
      expect(described_class.supports?("book")).to be true
      expect(described_class.supports?("article")).to be true
      expect(described_class.supports?("chapter")).to be true
    end

    it "returns false for unknown elements" do
      expect(described_class.supports?("html")).to be false
    end
  end

  describe ".supported_root_elements" do
    it "includes book, article, chapter, section" do
      elements = described_class.supported_root_elements
      expect(elements).to include("book", "article", "chapter", "section")
    end
  end
end
