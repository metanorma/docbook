# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Mirror Transformer — Document Structure", :mirror do
  NS = 'xmlns="http://docbook.org/ns/docbook"'

  describe "document root" do
    it "produces a doc node type" do
      xml = "<book #{NS}><info><title>My Book</title></info><chapter><title>Ch1</title><para>Hello</para></chapter></book>"
      result = mirror_hash(xml)
      expect(result["type"]).to eq("doc")
      expect(result["attrs"]["title"]).to eq("My Book")
      expect(result["content"]).not_to be_empty
    end

    it "preserves info title over book title" do
      xml = "<book #{NS}><info><title>Info Title</title></info><title>Book Title</title><chapter><title>Ch1</title><para>Text</para></chapter></book>"
      result = mirror_hash(xml)
      expect(result["attrs"]["title"]).to eq("Info Title")
    end
  end

  describe "section hierarchy" do
    it "produces chapter nodes from chapters" do
      xml = "<book #{NS}><title>Test</title><chapter><title>Chapter</title><section><title>Section</title><para>Text</para></section></chapter></book>"
      result = mirror_hash(xml)
      ch = find_node(result, "chapter")
      expect(ch).not_to be_nil
    end

    it "produces section nodes nested within chapters" do
      xml = "<book #{NS}><title>Test</title><chapter><title>Ch</title><section><title>S1</title><para>Text</para></section></chapter></book>"
      result = mirror_hash(xml)
      sections = collect_nodes(result, "section")
      expect(sections.length).to be >= 1
    end

    it "supports deep nesting: chapter > section > section > para" do
      xml = <<~XML
        <book #{NS}>
          <title>Deep</title>
          <chapter><title>Ch</title>
            <section><title>S1</title>
              <section><title>S2</title>
                <para>Deep content</para>
              </section>
            </section>
          </chapter>
        </book>
      XML
      result = mirror_hash(xml)
      deep_para = find_node(result, "paragraph")
      expect(deep_para).not_to be_nil
    end
  end

  describe "frontmatter elements" do
    it "produces a preface node" do
      xml = "<book #{NS}><title>Test</title><preface><title>Preface</title><para>Intro</para></preface><chapter><title>Ch</title><para>Body</para></chapter></book>"
      result = mirror_hash(xml)
      preface = find_node(result, "preface")
      expect(preface).not_to be_nil
      expect(preface["attrs"]["title"]).to eq("Preface")
    end

    it "produces a dedication node (as preface type)" do
      xml = "<book #{NS}><title>Test</title><dedication><title>Dedication</title><para>To you</para></dedication><chapter><title>Ch</title><para>Body</para></chapter></book>"
      result = mirror_hash(xml)
      dedication = find_node(result, "preface")
      expect(dedication).not_to be_nil
      expect(dedication["attrs"]["title"]).to eq("Dedication")
    end
  end

  describe "backmatter elements" do
    it "produces a glossary section" do
      xml = <<~XML
        <book #{NS}>
          <title>Test</title>
          <chapter><title>Ch</title><para>Body</para></chapter>
          <glossary>
            <glossentry>
              <glossterm>Term</glossterm>
              <glossdef><para>Definition</para></glossdef>
            </glossentry>
          </glossary>
        </book>
      XML
      result = mirror_hash(xml)
      gl = find_node(result, "glossary")
      expect(gl).not_to be_nil
    end

    it "produces a bibliography section" do
      xml = <<~XML
        <book #{NS}>
          <title>Test</title>
          <chapter><title>Ch</title><para>Body</para></chapter>
          <bibliography>
            <bibliomixed xml:id="ref1"><para>Author, Title</para></bibliomixed>
          </bibliography>
        </book>
      XML
      result = mirror_hash(xml)
      bib = find_node(result, "bibliography")
      expect(bib).not_to be_nil
    end

    it "produces an index section" do
      xml = <<~XML
        <book #{NS}>
          <title>Test</title>
          <chapter><title>Ch</title><para>Body</para></chapter>
          <index/>
        </book>
      XML
      result = mirror_hash(xml)
      idx = find_node(result, "index_block")
      expect(idx).not_to be_nil
    end
  end

  describe "special characters" do
    it "handles Unicode text" do
      xml = "<book #{NS}><title>Test</title><chapter><title>Ch</title><para>Hello 世界 🌍</para></chapter></book>"
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      expect(para["content"].first["text"]).to include("世界")
    end

    it "handles XML entities" do
      xml = "<book #{NS}><title>Test</title><chapter><title>Ch</title><para>A &amp; B &lt; C</para></chapter></book>"
      result = mirror_hash(xml)
      para = find_node(result, "paragraph")
      all_text = para["content"].map { |n| n["text"] }.join
      expect(all_text).to include("&")
      expect(all_text).to include("<")
    end
  end
end
