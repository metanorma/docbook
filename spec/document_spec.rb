# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Document do
  describe ".from_xml" do
    it "parses an article root element" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.1">
          <para>Hello</para>
        </article>
      XML
      result = described_class.from_xml(xml)
      expect(result).to be_a(Docbook::Elements::Article)
    end

    it "parses a book root element" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.1">
          <chapter><para>Hello</para></chapter>
        </book>
      XML
      result = described_class.from_xml(xml)
      expect(result).to be_a(Docbook::Elements::Book)
    end

    it "raises on unsupported root element" do
      xml = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <unknown xmlns="http://docbook.org/ns/docbook"/>
      XML
      expect { described_class.from_xml(xml) }.to raise_error(Docbook::Error, /Unsupported/)
    end
  end

  describe ".supports?" do
    it "returns true for supported elements" do
      expect(described_class.supports?("article")).to be true
      expect(described_class.supports?("book")).to be true
      expect(described_class.supports?("chapter")).to be true
    end

    it "returns false for unsupported elements" do
      expect(described_class.supports?("unknown")).to be false
    end
  end

  describe ".supported_root_elements" do
    it "returns a list of supported root element names" do
      elements = described_class.supported_root_elements
      expect(elements).to include("article", "book", "chapter", "appendix")
    end
  end
end
