# frozen_string_literal: true

RSpec.describe Docbook::Mirror::DocbookToMirror do
  let(:transformer) { described_class.new }

  describe "#call" do
    it "transforms simple paragraph" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Hello world</para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.call(doc)

      expect(result.type).to eq("doc")
      expect(result.content.first.type).to eq("paragraph")
      expect(result.content.first.content.first.text).to eq("Hello world")
    end

    it "transforms emphasis to mark" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>The word <emphasis>must</emphasis> is important</para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.call(doc)

      para = result.content.first
      emphasis_node = para.content.find { |n| n.marks&.first&.type == "emphasis" }
      expect(emphasis_node.text).to eq("must")
    end

    it "transforms code block" do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><section><programlisting language="ruby">def hello; end</programlisting></section></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.call(doc)

      section = result.content.first
      code_block = section.content.first
      expect(code_block.type).to eq("code_block")
      expect(code_block.attrs[:language]).to eq("ruby")
    end

    it "transforms admonition" do
      xml = <<~XML
        <article xmlns="http://docbook.org/ns/docbook">
          <section>
            <note><para>This is a note.</para></note>
          </section>
        </article>
      XML
      doc = Docbook::Document.from_xml(xml)
      result = transformer.call(doc)

      section = result.content.first
      admonition = section.content.first
      expect(admonition.type).to eq("admonition")
      expect(admonition.attrs[:admonition_type]).to eq("note")
    end
  end

  describe "with custom registry" do
    it "allows injecting a custom registry" do
      custom_registry = Docbook::Mirror::HandlerRegistry.new
      # Only register Para
      custom_registry.register(Docbook::Elements::Para, Docbook::Mirror::Handlers::Paragraph)

      ctx = described_class.new(registry: custom_registry)
      expect(ctx.registry).to eq(custom_registry)
    end
  end
end
