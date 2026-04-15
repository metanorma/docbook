# frozen_string_literal: true

RSpec.describe Docbook::Mirror::Transformer do
  let(:transformer) { described_class.new }

  describe '#from_docbook' do
    it 'transforms simple paragraph' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Hello world</para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      expect(result.type).to eq('doc')
      expect(result.content.first.type).to eq('paragraph')
      expect(result.content.first.content.first.text).to eq('Hello world')
    end

    it 'transforms emphasis to mark' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>The word <emphasis>must</emphasis> is important</para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      para = result.content.first
      text_nodes = para.content

      # Find text node with emphasis mark
      emphasis_node = text_nodes.find { |n| n.marks&.first&.type == 'emphasis' }
      expect(emphasis_node.text).to eq('must')
    end

    it 'transforms literal to code mark with role' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Set to <literal>notAllowed</literal></para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      para = result.content.first
      text_nodes = para.content

      # Find text node with code mark
      code_node = text_nodes.find { |n| n.marks&.first&.type == 'code' }
      expect(code_node.text).to eq('notAllowed')
      expect(code_node.marks.first.attrs[:role]).to eq('literal')
    end

    it 'transforms quote with nested literal (BUG FIX)' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>This is a <quote><literal>notAllowed</literal></quote> test.</para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      para = result.content.first
      # Find the text node with code mark (from quote's literal)
      code_node = para.content.find do |n|
        n.type == 'text' && n.marks&.first&.type == 'code'
      end

      expect(code_node).not_to be_nil
      expect(code_node.text).to eq('notAllowed')
      expect(code_node.marks.first.type).to eq('code')
    end

    it 'transforms self-closing link with host as text' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>See <link xlink:href="http://docbook.org/"/></para></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      para = result.content.first
      link_text_node = para.content.find do |n|
        n.type == 'text' && n.marks&.first&.type == 'link'
      end

      expect(link_text_node.text).to eq('docbook.org')
      expect(link_text_node.marks.first.attrs[:href]).to eq('http://docbook.org/')
    end

    it 'transforms code block' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><section><programlisting language="ruby">def hello; end</programlisting></section></article>'
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      section = result.content.first
      code_block = section.content.first
      expect(code_block.type).to eq('code_block')
      expect(code_block.attrs[:language]).to eq('ruby')
      expect(code_block.content.first.text).to include('def hello')
    end

    it 'transforms ordered list' do
      xml = <<~XML
        <article xmlns="http://docbook.org/ns/docbook">
          <section>
            <orderedlist>
              <listitem><para>First</para></listitem>
              <listitem><para>Second</para></listitem>
            </orderedlist>
          </section>
        </article>
      XML
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      section = result.content.first
      ordered_list = section.content.first
      expect(ordered_list.type).to eq('ordered_list')
      expect(ordered_list.content.size).to eq(2)
    end

    it 'transforms admonition' do
      xml = <<~XML
        <article xmlns="http://docbook.org/ns/docbook">
          <section>
            <note><para>This is a note.</para></note>
          </section>
        </article>
      XML
      doc = Docbook::Document.from_xml(xml)
      result = transformer.from_docbook(doc)

      section = result.content.first
      admonition = section.content.first
      expect(admonition.type).to eq('admonition')
      expect(admonition.attrs[:admonition_type]).to eq('note')
    end
  end

  describe '#to_docbook' do
    it 'round-trips simple paragraph' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Hello world</para></article>'
      doc = Docbook::Document.from_xml(xml)
      mirror_doc = transformer.from_docbook(doc)
      doc2 = transformer.to_docbook(mirror_doc)

      expect(doc2.para.first.content).to include('Hello world')
    end

    it 'preserves literal content in round-trip' do
      xml = '<article xmlns="http://docbook.org/ns/docbook"><para>Use <literal>notAllowed</literal> here.</para></article>'
      doc = Docbook::Document.from_xml(xml)
      mirror_doc = transformer.from_docbook(doc)
      doc2 = transformer.to_docbook(mirror_doc)

      # The literal content should be preserved
      literal = doc2.para.first.literal.first
      expect(literal.content).to eq('notAllowed')
    end
  end
end