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
end
