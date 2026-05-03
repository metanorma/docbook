# frozen_string_literal: true

RSpec.describe Docbook::Services::IndexGenerator do
  describe "#generate" do
    it "collects indexterm elements from document" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <chapter xml:id="ch1">
            <title>Chapter</title>
            <para>Text</para>
            <indexterm xml:id="idx1"><primary>Alpha</primary></indexterm>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      expect(entries.size).to be >= 1
      expect(entries.map(&:primary)).to include("Alpha")
    end

    it "includes section context for each entry" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter xml:id="ch1"><title>My Chapter</title>
            <para>Text</para>
            <indexterm><primary>Beta</primary></indexterm>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      entry = entries.find { |e| e.primary == "Beta" }
      expect(entry).not_to be_nil
      expect(entry.section_id).not_to be_empty
    end

    it "extracts secondary terms" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter><title>Ch</title>
            <indexterm><primary>Alpha</primary><secondary>Beta</secondary></indexterm>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      entry = entries.first
      expect(entry.secondary).to include("Beta")
    end

    it "extracts see_also references" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter><title>Ch</title>
            <indexterm><primary>Alpha</primary><seealso>Beta</seealso></indexterm>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      entry = entries.first
      expect(entry.see_also).to include("Beta")
    end

    it "sorts entries alphabetically" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter><title>Ch</title>
            <indexterm><primary>Zebra</primary></indexterm>
            <indexterm><primary>Alpha</primary></indexterm>
            <indexterm><primary>Middle</primary></indexterm>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      primaries = entries.map(&:primary).uniq
      expect(primaries).to eq(%w[Alpha Middle Zebra])
    end

    it "returns empty array for document with no index terms" do
      xml = '<book xmlns="http://docbook.org/ns/docbook"><title>Empty</title></book>'
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      expect(entries).to eq([])
    end

    it "generates sort key from primary text" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter><title>Ch</title>
            <indexterm><primary>  Mixed Case  </primary></indexterm>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      entries = described_class.new(doc).generate

      expect(entries.first.sort_key).to eq("mixed case")
    end
  end
end
