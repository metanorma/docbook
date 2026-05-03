# frozen_string_literal: true

RSpec.describe Docbook::Services::NumberingService do
  describe "#generate" do
    it "numbers chapters sequentially" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <chapter xml:id="ch1"><title>First</title><para>Text</para></chapter>
          <chapter xml:id="ch2"><title>Second</title><para>Text</para></chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      numbering = described_class.new(doc).generate

      ch1 = numbering.find { |n| n.id == "ch1" }
      ch2 = numbering.find { |n| n.id == "ch2" }
      expect(ch1.number).to eq("1")
      expect(ch2.number).to eq("2")
    end

    it "numbers parts with Roman numerals" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <part xml:id="p1"><title>Part One</title><chapter xml:id="ch1"><title>Ch</title><para>Text</para></chapter></part>
          <part xml:id="p2"><title>Part Two</title><chapter xml:id="ch2"><title>Ch</title><para>Text</para></chapter></part>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      numbering = described_class.new(doc).generate

      p1 = numbering.find { |n| n.id == "p1" }
      p2 = numbering.find { |n| n.id == "p2" }
      expect(p1.number).to eq("I")
      expect(p2.number).to eq("II")
    end

    it "numbers sections hierarchically within chapters" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <chapter xml:id="ch1">
            <title>Chapter</title>
            <section xml:id="s1"><title>Section 1</title><para>Text</para></section>
            <section xml:id="s2">
              <title>Section 2</title>
              <para>Text</para>
              <section xml:id="s2_1"><title>Subsection</title><para>Text</para></section>
            </section>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      numbering = described_class.new(doc).generate

      s1 = numbering.find { |n| n.id == "s1" }
      s2 = numbering.find { |n| n.id == "s2" }
      s2_1 = numbering.find { |n| n.id == "s2_1" }
      expect(s1.number).to eq("1")
      expect(s2.number).to eq("2")
      expect(s2_1.number).to eq("2.1")
    end

    it "numbers appendices with letters" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <appendix xml:id="a1"><title>Appendix A</title><para>Text</para></appendix>
          <appendix xml:id="a2"><title>Appendix B</title><para>Text</para></appendix>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      numbering = described_class.new(doc).generate

      a1 = numbering.find { |n| n.id == "a1" }
      a2 = numbering.find { |n| n.id == "a2" }
      expect(a1.number).to eq("A")
      expect(a2.number).to eq("B")
    end

    it "returns empty array for document without sections" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Just a paragraph</para></article>'
      doc = Docbook::Document.from_xml(xml)
      numbering = described_class.new(doc).generate

      expect(numbering).to eq([])
    end
  end
end
