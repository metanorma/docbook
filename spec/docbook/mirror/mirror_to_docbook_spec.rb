# frozen_string_literal: true

RSpec.describe Docbook::Mirror::MirrorToDocbook do
  let(:converter) { described_class.new }

  def roundtrip(xml)
    doc = Docbook::Document.from_xml(xml)
    mirror_doc = Docbook::Mirror::DocbookToMirror.new.call(doc)
    converter.call(mirror_doc)
  end

  describe "#call" do
    it "round-trips simple paragraph" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Hello world</para></article>'
      doc2 = roundtrip(xml)

      expect(doc2).to be_a(Docbook::Elements::Article)
      expect(doc2.para.first.content).to include("Hello world")
    end

    it "round-trips literal content" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Use <literal>notAllowed</literal> here.</para></article>'
      doc2 = roundtrip(xml)

      literal = doc2.para.first.literal.first
      expect(literal.content).to eq(["notAllowed"])
    end

    it "round-trips code block within chapter" do
      xml = '<book xmlns="http://docbook.org/ns/docbook"><title>T</title><chapter><title>C</title><programlisting>puts "hello"</programlisting></chapter></book>'
      doc = Docbook::Document.from_xml(xml)
      mirror_doc = Docbook::Mirror::DocbookToMirror.new.call(doc)
      doc2 = converter.call(mirror_doc)

      expect(doc2).to be_a(Docbook::Elements::Article)
    end

    it "round-trips emphasis with role" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para><emphasis role="bold">Strong text</emphasis></para></article>'
      doc2 = roundtrip(xml)

      emphasis = doc2.para.first.emphasis.first
      expect(emphasis.content.join).to eq("Strong text")
      expect(emphasis.role).to eq("bold")
    end

    it "round-trips link" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para><link xlink:href="http://example.com">Example</link></para></article>'
      doc2 = roundtrip(xml)

      link = doc2.para.first.link.first
      expect(link.content.join).to eq("Example")
    end

    it "round-trips xref" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>See <xref linkend="ch1"/>.</para></article>'
      doc2 = roundtrip(xml)

      xref = doc2.para.first.xref.first
      expect(xref).not_to be_nil
    end
  end

  describe "role_to_class" do
    it "resolves literal role to Literal class" do
      result = converter.role_to_class("literal")
      expect(result).to eq(Docbook::Elements::Literal)
    end

    it "resolves code role to Code class" do
      result = converter.role_to_class("code")
      expect(result).to eq(Docbook::Elements::Code)
    end

    it "resolves userinput role to UserInput class" do
      result = converter.role_to_class("userinput")
      expect(result).to eq(Docbook::Elements::UserInput)
    end

    it "falls back to Literal for unknown roles" do
      result = converter.role_to_class("nonexistent_element")
      expect(result).to eq(Docbook::Elements::Literal)
    end
  end
end
