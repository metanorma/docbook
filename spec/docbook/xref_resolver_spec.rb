# frozen_string_literal: true

RSpec.describe Docbook::XrefResolver do
  describe "#resolve! and #title_for" do
    it "resolves chapter titles by xml:id" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <chapter xml:id="ch1"><title>Introduction</title><para>Text</para></chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      resolver = described_class.new(doc).resolve!

      expect(resolver.title_for("ch1")).to eq("Introduction")
    end

    it "resolves section titles" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter xml:id="ch1">
            <title>Chapter</title>
            <section xml:id="s1"><title>Overview</title><para>Text</para></section>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      resolver = described_class.new(doc).resolve!

      expect(resolver.title_for("s1")).to eq("Overview")
    end

    it "returns nil for unknown IDs" do
      xml = '<book xmlns="http://docbook.org/ns/docbook"><title>Book</title></book>'
      doc = Docbook::Document.from_xml(xml)
      resolver = described_class.new(doc).resolve!

      expect(resolver.title_for("nonexistent")).to be_nil
    end

    it "resolves book title via info" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook" xml:id="mybook">
          <info><title>The Book</title></info>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      resolver = described_class.new(doc).resolve!

      expect(resolver.title_for("mybook")).to eq("The Book")
    end

    it "resolves figure titles" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter xml:id="ch1">
            <title>Ch</title>
            <figure xml:id="fig1">
              <title>Diagram</title>
              <mediaobject><imageobject><imagedata fileref="img.png"/></imageobject></mediaobject>
            </figure>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      resolver = described_class.new(doc).resolve!

      expect(resolver.title_for("fig1")).to eq("Diagram")
    end
  end

  describe "#[]" do
    it "returns the element by xml:id" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter xml:id="ch1"><title>Chapter</title><para>Text</para></chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      resolver = described_class.new(doc).resolve!

      expect(resolver["ch1"]).to be_a(Docbook::Elements::Chapter)
    end
  end
end
