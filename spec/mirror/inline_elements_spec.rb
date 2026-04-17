# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Mirror Transformer — Inline Elements", :mirror do
  NS = 'xmlns="http://docbook.org/ns/docbook"'
  XLINK = 'xmlns:xlink="http://www.w3.org/1999/xlink"'

  def chapter_xml(inner)
    "<book #{NS} #{XLINK}><title>Test</title><chapter><title>Ch1</title><para>#{inner}</para></chapter></book>"
  end

  describe "emphasis" do
    it "produces emphasis marks from emphasis" do
      xml = chapter_xml("This is <emphasis>emphasized</emphasis> text")
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      text_nodes = para["content"]
      em_node = text_nodes.find { |n| n["marks"]&.any? { |m| m["type"] == "emphasis" } }
      expect(em_node).not_to be_nil
      expect(em_node["text"]).to eq("emphasized")
    end

    it "produces strong marks from emphasis with role=strong" do
      xml = chapter_xml('This is <emphasis role="strong">bold</emphasis> text')
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      text_nodes = para["content"]
      bold_node = text_nodes.find { |n| n["marks"]&.any? { |m| m["type"] == "strong" } }
      expect(bold_node).not_to be_nil
      expect(bold_node["text"]).to eq("bold")
    end
  end

  describe "code" do
    it "produces code marks from inline code" do
      xml = chapter_xml("Use <code>puts</code> here")
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      text_nodes = para["content"]
      code_node = text_nodes.find { |n| n["marks"]&.any? { |m| m["type"] == "code" } }
      expect(code_node).not_to be_nil
      expect(code_node["text"]).to eq("puts")
    end
  end

  describe "link" do
    it "produces link marks from xlink:href" do
      xml = chapter_xml('Click <link xlink:href="https://example.com">here</link>')
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      text_nodes = para["content"]
      link_node = text_nodes.find { |n| n["marks"]&.any? { |m| m["type"] == "link" } }
      expect(link_node).not_to be_nil
      expect(link_node["text"]).to eq("here")
      link_mark = link_node["marks"].find { |m| m["type"] == "link" }
      expect(link_mark["attrs"]["href"]).to eq("https://example.com")
    end
  end

  describe "xref" do
    it "produces a text node with xref mark" do
      xml = chapter_xml('See <xref linkend="ch01"/> for details')
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      xref_node = para["content"].find { |n| n["marks"]&.any? { |m| m["type"] == "xref" } }
      expect(xref_node).not_to be_nil
    end
  end

  describe "subscript and superscript" do
    it "produces subscript marks" do
      xml = chapter_xml("H<subscript>2</subscript>O")
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      sub_node = para["content"].find { |n| n["marks"]&.any? { |m| m["type"] == "subscript" } }
      expect(sub_node).not_to be_nil
      expect(sub_node["text"]).to eq("2")
    end

    it "produces superscript marks" do
      xml = chapter_xml("E=mc<superscript>2</superscript>")
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      sup_node = para["content"].find { |n| n["marks"]&.any? { |m| m["type"] == "superscript" } }
      expect(sup_node).not_to be_nil
      expect(sup_node["text"]).to eq("2")
    end
  end
end
