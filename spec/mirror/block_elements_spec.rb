# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Mirror Transformer — Block Elements", :mirror do
  NS = 'xmlns="http://docbook.org/ns/docbook"'

  def chapter_xml(inner)
    "<book #{NS}><title>Test</title><chapter><title>Ch1</title>#{inner}</chapter></book>"
  end

  describe "paragraph" do
    it "produces a paragraph node with text content" do
      xml = chapter_xml("<para>Hello world</para>")
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      expect(para).not_to be_nil
      text_node = para["content"]&.first
      expect(text_node["type"]).to eq("text")
      expect(text_node["text"]).to eq("Hello world")
    end
  end

  describe "code_block" do
    it "produces a code_block node from programlisting" do
      xml = chapter_xml("<programlisting>puts 'hello'</programlisting>")
      result = mirror_hash(xml)
      code = find_node(result, "code_block")
      expect(code).not_to be_nil
      expect(code["content"].first["text"]).to include("puts 'hello'")
    end

    it "produces a code_block from screen" do
      xml = chapter_xml("<screen>$ echo hello</screen>")
      result = mirror_hash(xml)
      code = find_node(result, "code_block")
      expect(code).not_to be_nil
    end
  end

  describe "lists" do
    it "produces an ordered_list from orderedlist" do
      xml = chapter_xml("<orderedlist><listitem><para>First</para></listitem><listitem><para>Second</para></listitem></orderedlist>")
      result = mirror_hash(xml)
      list = find_node(result, "ordered_list")
      expect(list).not_to be_nil
      items = list["content"]
      expect(items.length).to eq(2)
    end

    it "produces a bullet_list from itemizedlist" do
      xml = chapter_xml("<itemizedlist><listitem><para>One</para></listitem></itemizedlist>")
      result = mirror_hash(xml)
      list = find_node(result, "bullet_list")
      expect(list).not_to be_nil
    end

    it "produces a dl (definition list) from variablelist" do
      xml = chapter_xml("<variablelist><varlistentry><term>Key</term><listitem><para>Value</para></listitem></varlistentry></variablelist>")
      result = mirror_hash(xml)
      list = find_node(result, "dl")
      expect(list).not_to be_nil
    end
  end

  describe "blockquote" do
    it "produces a blockquote node" do
      xml = chapter_xml("<blockquote><para>Quoted text</para></blockquote>")
      result = mirror_hash(xml)
      bq = find_node(result, "blockquote")
      expect(bq).not_to be_nil
    end
  end

  describe "admonitions" do
    %w[note tip important warning caution].each do |type|
      it "produces an admonition node from #{type}" do
        xml = chapter_xml("<#{type}><para>#{type.capitalize} message</para></#{type}>")
        result = mirror_hash(xml)
        admon = find_node(result, "admonition")
        expect(admon).not_to be_nil
        expect(admon["attrs"]["admonition_type"]).to eq(type)
      end
    end
  end

  describe "figure" do
    it "produces an image node from figure with mediaobject" do
      xml = chapter_xml('<figure><title>A Figure</title><mediaobject><imageobject><imagedata fileref="test.png"/></imageobject></mediaobject></figure>')
      result = mirror_hash(xml)
      img = find_node(result, "image")
      expect(img).not_to be_nil
    end
  end

  describe "example" do
    it "produces a code_block from example with programlisting" do
      xml = chapter_xml("<example><title>An Example</title><programlisting>code</programlisting></example>")
      result = mirror_hash(xml)
      code = find_node(result, "code_block")
      expect(code).not_to be_nil
    end
  end

  describe "annotation" do
    it "produces an annotation node with content" do
      xml = chapter_xml('<annotation xml:id="ann1"><para>This is a note</para></annotation>')
      result = mirror_hash(xml)
      ann = find_node(result, "annotation")
      expect(ann).not_to be_nil
      expect(ann["attrs"]["xml_id"]).to eq("ann1")
      para = find_node(ann, "paragraph")
      expect(para).not_to be_nil
    end

    it "preserves multiple paragraphs in annotation" do
      xml = chapter_xml('<annotation xml:id="ann2"><para>First</para><para>Second</para></annotation>')
      result = mirror_hash(xml)
      ann = find_node(result, "annotation")
      expect(ann).not_to be_nil
      paras = collect_nodes(ann, "paragraph")
      expect(paras.length).to eq(2)
    end

    it "handles annotation without xml_id" do
      xml = chapter_xml("<annotation><para>Simple note</para></annotation>")
      result = mirror_hash(xml)
      ann = find_node(result, "annotation")
      expect(ann).not_to be_nil
      expect(ann["attrs"]).to be_nil
    end

    it "uses fallback text when annotation has no para" do
      xml = chapter_xml("<annotation>Plain text annotation</annotation>")
      result = mirror_hash(xml)
      ann = find_node(result, "annotation")
      expect(ann).not_to be_nil
      text = find_node(ann, "text")
      expect(text["text"]).to eq("Plain text annotation")
    end
  end

  describe "callout markers" do
    it "inserts numbered callout markers in code blocks" do
      xml = chapter_xml('<programlisting>line one<co xml:id="co1"/>line two<co xml:id="co2"/></programlisting>')
      result = mirror_hash(xml)
      code = find_node(result, "code_block")
      expect(code).not_to be_nil
      text = code["content"].first["text"]
      expect(text).to include("(1)")
      expect(text).to include("(2)")
    end

    it "includes callout metadata in attrs" do
      xml = chapter_xml('<programlisting>code<co xml:id="co1"/></programlisting>')
      result = mirror_hash(xml)
      code = find_node(result, "code_block")
      expect(code["attrs"]["callouts"]).not_to be_nil
      expect(code["attrs"]["callouts"].length).to eq(1)
      expect(code["attrs"]["callouts"][0][:id]).to eq("co1")
      expect(code["attrs"]["callouts"][0][:number]).to eq(1)
    end

    it "renders calloutlist with items" do
      xml = chapter_xml('<calloutlist><callout arearefs="co1"><para>Description of callout 1</para></callout></calloutlist>')
      result = mirror_hash(xml)
      list = find_node(result, "calloutlist")
      expect(list).not_to be_nil
      callouts = list["content"]
      expect(callouts.length).to eq(1)
      expect(callouts[0]["attrs"]["arearefs"]).to eq("co1")
    end

    it "handles multiple callouts in a calloutlist" do
      xml = chapter_xml('<calloutlist><callout arearefs="co1"><para>First</para></callout><callout arearefs="co2"><para>Second</para></callout></calloutlist>')
      result = mirror_hash(xml)
      list = find_node(result, "calloutlist")
      expect(list["content"].length).to eq(2)
    end

    it "preserves custom label on co element" do
      xml = chapter_xml('<programlisting>code<co xml:id="coA" label="a"/></programlisting>')
      result = mirror_hash(xml)
      code = find_node(result, "code_block")
      expect(code["attrs"]["callouts"][0][:label]).to eq("a")
      text = code["content"].first["text"]
      expect(text).to include("(a)")
    end
  end

  describe "qandaset" do
    it "produces a qandaset with entries" do
      xml = chapter_xml("<qandaset><qandaentry><question><para>What is X?</para></question><answer><para>X is Y.</para></answer></qandaentry></qandaset>")
      result = mirror_hash(xml)
      qas = find_node(result, "qandaset")
      expect(qas).not_to be_nil
      entry = find_node(qas, "qandaentry")
      expect(entry).not_to be_nil
    end

    it "produces question and answer nodes" do
      xml = chapter_xml("<qandaset><qandaentry><question><para>What?</para></question><answer><para>This.</para></answer></qandaentry></qandaset>")
      result = mirror_hash(xml)
      q = find_node(result, "question")
      a = find_node(result, "answer")
      expect(q).not_to be_nil
      expect(a).not_to be_nil
    end

    it "preserves qandaset title" do
      xml = chapter_xml("<qandaset><title>FAQ</title><qandaentry><question><para>Q1</para></question><answer><para>A1</para></answer></qandaentry></qandaset>")
      result = mirror_hash(xml)
      qas = find_node(result, "qandaset")
      expect(qas["attrs"]["title"]).to eq("FAQ")
    end

    it "supports multiple answers per entry" do
      xml = chapter_xml("<qandaset><qandaentry><question><para>Q</para></question><answer><para>A1</para></answer><answer><para>A2</para></answer></qandaentry></qandaset>")
      result = mirror_hash(xml)
      answers = collect_nodes(result, "answer")
      expect(answers.length).to eq(2)
    end
  end

  describe "sidebar" do
    it "produces a sidebar node with title and content" do
      xml = chapter_xml('<sidebar><title>Aside</title><para>Extra info</para></sidebar>')
      result = mirror_hash(xml)
      sb = find_node(result, "sidebar")
      expect(sb).not_to be_nil
      expect(sb["attrs"]["title"]).to eq("Aside")
      para = find_node(sb, "paragraph")
      expect(para).not_to be_nil
    end

    it "produces a sidebar without title" do
      xml = chapter_xml('<sidebar><para>Just content</para></sidebar>')
      result = mirror_hash(xml)
      sb = find_node(result, "sidebar")
      expect(sb).not_to be_nil
      expect(sb["attrs"]).to be_nil
    end
  end

  describe "procedure and steps" do
    it "produces a procedure with steps" do
      xml = chapter_xml('<procedure><title>Setup</title><step><para>Download</para></step><step><para>Install</para></step></procedure>')
      result = mirror_hash(xml)
      proc = find_node(result, "procedure")
      expect(proc).not_to be_nil
      expect(proc["attrs"]["title"]).to eq("Setup")
      steps = collect_nodes(proc, "step")
      expect(steps.length).to eq(2)
    end

    it "produces substeps within a step" do
      xml = chapter_xml('<procedure><step><para>Main step</para><substeps><step><para>Sub 1</para></step></substeps></step></procedure>')
      result = mirror_hash(xml)
      proc = find_node(result, "procedure")
      expect(proc).not_to be_nil
      substeps = find_node(proc, "substeps")
      expect(substeps).not_to be_nil
    end
  end

  describe "footnotes" do
    it "produces footnote markers and entries" do
      xml = chapter_xml('<para>Text with a note<footnote><para>This is the note</para></footnote>.</para>')
      result = mirror_hash(xml)
      marker = find_node(result, "footnote_marker")
      expect(marker).not_to be_nil
      expect(marker["attrs"]["number"]).to eq(1)
    end
  end
end
