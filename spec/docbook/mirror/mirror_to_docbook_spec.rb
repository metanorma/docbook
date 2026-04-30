# frozen_string_literal: true

RSpec.describe Docbook::Mirror::MirrorToDocbook do
  let(:converter) { described_class.new }

  describe "#call" do
    it "round-trips simple paragraph" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Hello world</para></article>'
      doc = Docbook::Document.from_xml(xml)
      mirror_doc = Docbook::Mirror::DocbookToMirror.new.call(doc)
      doc2 = converter.call(mirror_doc)

      expect(doc2).to be_a(Docbook::Elements::Article)
      expect(doc2.para.first.content).to include("Hello world")
    end

    it "round-trips literal content" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Use <literal>notAllowed</literal> here.</para></article>'
      doc = Docbook::Document.from_xml(xml)
      mirror_doc = Docbook::Mirror::DocbookToMirror.new.call(doc)
      doc2 = converter.call(mirror_doc)

      literal = doc2.para.first.literal.first
      expect(literal.content).to eq(["notAllowed"])
    end
  end
end
