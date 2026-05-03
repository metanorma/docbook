# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Element Concerns" do
  describe "DocbookElement (base concern)" do
    it "provides default section_like? as false" do
      el = Docbook::Elements::Para.new
      expect(el.section_like?).to be false
    end

    it "provides default xml_id as nil" do
      el = Docbook::Elements::Para.new
      expect(el.xml_id).to be_nil
    end

    it "provides default resolve_title as nil" do
      el = Docbook::Elements::Para.new
      expect(el.resolve_title).to be_nil
    end

    it "provides default has_title? as false" do
      el = Docbook::Elements::Para.new
      expect(el.has_title?).to be false
    end

    it "provides default titled? as false" do
      el = Docbook::Elements::Para.new
      expect(el.titled?).to be false
    end

    it "provides default toc_children as empty array" do
      el = Docbook::Elements::Para.new
      expect(el.toc_children).to eq([])
    end

    it "provides default numbering_role as nil" do
      el = Docbook::Elements::Para.new
      expect(el.numbering_role).to be_nil
    end

    it "provides default stats_category as nil" do
      el = Docbook::Elements::Para.new
      expect(el.stats_category).to be_nil
    end

    it "provides default formal? as false" do
      el = Docbook::Elements::Para.new
      expect(el.formal?).to be false
    end

    it "provides default list_of_category as nil" do
      el = Docbook::Elements::Para.new
      expect(el.list_of_category).to be_nil
    end

    it "provides default index_term? as false" do
      el = Docbook::Elements::Para.new
      expect(el.index_term?).to be false
    end

    it "generates synthetic element_id" do
      el = Docbook::Elements::Para.new
      expect(el.element_id).to start_with("elem-")
    end

    it "uses xml_id for element_id when present" do
      el = Docbook::Elements::Chapter.from_xml('<chapter xmlns="http://docbook.org/ns/docbook" xml:id="intro"><title>Intro</title></chapter>')
      expect(el.element_id).to eq("intro")
    end

    describe "#walk_children" do
      it "yields child Serializable elements" do
        xml = <<~XML
          <chapter xmlns="http://docbook.org/ns/docbook">
            <title>Test</title>
            <para>Hello</para>
            <para>World</para>
          </chapter>
        XML
        chapter = Docbook::Elements::Chapter.from_xml(xml)
        children = []
        chapter.walk_children { |c| children << c }
        types = children.map { |c| c.class.name.split("::").last }
        expect(types).to include("Title", "Para", "Para")
      end
    end
  end

  describe "Titled concern" do
    it "resolves title from title element" do
      xml = '<chapter xmlns="http://docbook.org/ns/docbook"><title>My Chapter</title><para>text</para></chapter>'
      ch = Docbook::Elements::Chapter.from_xml(xml)
      expect(ch.resolve_title).to eq("My Chapter")
    end

    it "resolves title from info.title" do
      xml = '<book xmlns="http://docbook.org/ns/docbook"><info><title>My Book</title></info></book>'
      book = Docbook::Elements::Book.from_xml(xml)
      expect(book.resolve_title).to eq("My Book")
    end

    it "returns true for titled?" do
      ch = Docbook::Elements::Chapter.from_xml('<chapter xmlns="http://docbook.org/ns/docbook"><title>X</title></chapter>')
      expect(ch.titled?).to be true
    end

    it "has_title? returns true when title has content" do
      ch = Docbook::Elements::Chapter.from_xml('<chapter xmlns="http://docbook.org/ns/docbook"><title>X</title></chapter>')
      expect(ch.has_title?).to be true
    end

    it "has_title? returns false when title is blank" do
      ch = Docbook::Elements::Chapter.from_xml('<chapter xmlns="http://docbook.org/ns/docbook"><title>   </title></chapter>')
      expect(ch.has_title?).to be false
    end
  end

  describe "SectionLike concern" do
    it "returns true for section-like elements" do
      expect(Docbook::Elements::Chapter.new.section_like?).to be true
      expect(Docbook::Elements::Section.new.section_like?).to be true
      expect(Docbook::Elements::Book.new.section_like?).to be true
      expect(Docbook::Elements::Article.new.section_like?).to be true
    end

    it "returns false for non-section elements" do
      expect(Docbook::Elements::Para.new.section_like?).to be false
      expect(Docbook::Elements::Figure.new.section_like?).to be false
    end
  end

  describe "TocContainer concern" do
    it "Book returns correct toc_children" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Book</title>
          <chapter xml:id="c1"><title>Ch1</title></chapter>
          <chapter xml:id="c2"><title>Ch2</title></chapter>
          <appendix xml:id="a1"><title>App1</title></appendix>
        </book>
      XML
      book = Docbook::Elements::Book.from_xml(xml)
      ids = book.toc_children.map { |c| c.xml_id.to_s }
      expect(ids).to eq(%w[c1 c2 a1])
    end

    it "Article returns sections" do
      xml = <<~XML
        <article xmlns="http://docbook.org/ns/docbook">
          <section xml:id="s1"><title>S1</title></section>
          <section xml:id="s2"><title>S2</title></section>
        </article>
      XML
      article = Docbook::Elements::Article.from_xml(xml)
      ids = article.toc_children.map { |c| c.xml_id.to_s }
      expect(ids).to eq(%w[s1 s2])
    end

    it "Section returns nested sections" do
      xml = <<~XML
        <section xmlns="http://docbook.org/ns/docbook" xml:id="s1">
          <title>S1</title>
          <section xml:id="s1a"><title>S1a</title></section>
          <section xml:id="s1b"><title>S1b</title></section>
        </section>
      XML
      section = Docbook::Elements::Section.from_xml(xml)
      ids = section.toc_children.map { |c| c.xml_id.to_s }
      expect(ids).to eq(%w[s1a s1b])
    end

    it "leaf elements return empty toc_children" do
      expect(Docbook::Elements::Sect5.new.toc_children).to eq([])
    end
  end

  describe "Numberable concern" do
    it "Part has :part numbering role" do
      expect(Docbook::Elements::Part.new.numbering_role).to eq(:part)
    end

    it "Chapter has :chapter numbering role" do
      expect(Docbook::Elements::Chapter.new.numbering_role).to eq(:chapter)
    end

    it "Section has :section numbering role" do
      expect(Docbook::Elements::Section.new.numbering_role).to eq(:section)
    end

    it "Figure has :figure numbering role" do
      expect(Docbook::Elements::Figure.new.numbering_role).to eq(:figure)
    end

    it "Example has :example numbering role" do
      expect(Docbook::Elements::Example.new.numbering_role).to eq(:example)
    end

    it "Table has :table numbering role" do
      expect(Docbook::Elements::Table.new.numbering_role).to eq(:table)
    end

    it "Appendix has :appendix numbering role" do
      expect(Docbook::Elements::Appendix.new.numbering_role).to eq(:appendix)
    end

    it "non-numberable elements have nil role" do
      expect(Docbook::Elements::Para.new.numbering_role).to be_nil
    end
  end

  describe "RefEntry title resolution" do
    it "resolves title from refmeta" do
      xml = <<~XML
        <refentry xmlns="http://docbook.org/ns/docbook">
          <refmeta>
            <refentrytitle>function_name</refentrytitle>
          </refmeta>
          <refnamediv>
            <refname>function_name</refname>
            <refpurpose>Does something</refpurpose>
          </refnamediv>
        </refentry>
      XML
      entry = Docbook::Elements::RefEntry.from_xml(xml)
      expect(entry.resolve_title).to eq("function_name")
    end

    it "resolves title from refnamediv as fallback" do
      xml = <<~XML
        <refentry xmlns="http://docbook.org/ns/docbook">
          <refnamediv>
            <refname>func_a</refname>
            <refname>func_b</refname>
          </refnamediv>
        </refentry>
      XML
      entry = Docbook::Elements::RefEntry.from_xml(xml)
      expect(entry.resolve_title).to eq("func_a, func_b")
    end
  end

  describe "StatsCategory" do
    it "Figure returns :image" do
      expect(Docbook::Elements::Figure.new.stats_category).to eq(:image)
    end

    it "InformalFigure returns :image" do
      expect(Docbook::Elements::InformalFigure.new.stats_category).to eq(:image)
    end

    it "MediaObject returns :image" do
      expect(Docbook::Elements::MediaObject.new.stats_category).to eq(:image)
    end

    it "ProgramListing returns :code_block" do
      expect(Docbook::Elements::ProgramListing.new.stats_category).to eq(:code_block)
    end

    it "Screen returns :code_block" do
      expect(Docbook::Elements::Screen.new.stats_category).to eq(:code_block)
    end

    it "LiteralLayout returns :code_block" do
      expect(Docbook::Elements::LiteralLayout.new.stats_category).to eq(:code_block)
    end

    it "Table returns :table" do
      expect(Docbook::Elements::Table.new.stats_category).to eq(:table)
    end

    it "InformalTable returns :table" do
      expect(Docbook::Elements::InformalTable.new.stats_category).to eq(:table)
    end

    it "IndexTerm returns :index_term" do
      expect(Docbook::Elements::IndexTerm.new.stats_category).to eq(:index_term)
    end

    it "Bibliomixed returns :bibliography_entry" do
      expect(Docbook::Elements::Bibliomixed.new.stats_category).to eq(:bibliography_entry)
    end
  end

  describe "DocumentStats with stats_category" do
    let(:xml) do
      <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <title>Stats Test</title>
          <chapter><title>Ch1</title>
            <para>Some text</para>
            <programlisting>code here</programlisting>
            <screen>more code</screen>
            <figure><title>Fig1</title>
              <mediaobject><imageobject><imagedata fileref="test.png"/></imageobject></mediaobject>
            </figure>
          </chapter>
        </book>
      XML
    end

    it "counts sections via section_like?" do
      doc = Docbook::Document.from_xml(xml)
      stats = Docbook::Services::DocumentStats.new(doc).generate
      expect(stats["sections"]).to be >= 1
    end

    it "counts images via stats_category" do
      doc = Docbook::Document.from_xml(xml)
      stats = Docbook::Services::DocumentStats.new(doc).generate
      expect(stats["images"]).to be >= 1
    end

    it "counts code blocks via stats_category" do
      doc = Docbook::Document.from_xml(xml)
      stats = Docbook::Services::DocumentStats.new(doc).generate
      expect(stats["code_blocks"]).to be >= 2
    end
  end

  describe "Formal concern" do
    it "Figure is formal with list_of_category :figures" do
      fig = Docbook::Elements::Figure.new
      expect(fig.formal?).to be true
      expect(fig.list_of_category).to eq(:figures)
    end

    it "InformalFigure is formal with list_of_category :figures" do
      fig = Docbook::Elements::InformalFigure.new
      expect(fig.formal?).to be true
      expect(fig.list_of_category).to eq(:figures)
    end

    it "Table is formal with list_of_category :tables" do
      tbl = Docbook::Elements::Table.new
      expect(tbl.formal?).to be true
      expect(tbl.list_of_category).to eq(:tables)
    end

    it "InformalTable is formal with list_of_category :tables" do
      tbl = Docbook::Elements::InformalTable.new
      expect(tbl.formal?).to be true
      expect(tbl.list_of_category).to eq(:tables)
    end

    it "Example is formal with list_of_category :examples" do
      ex = Docbook::Elements::Example.new
      expect(ex.formal?).to be true
      expect(ex.list_of_category).to eq(:examples)
    end

    it "InformalExample is formal with list_of_category :examples" do
      ex = Docbook::Elements::InformalExample.new
      expect(ex.formal?).to be true
      expect(ex.list_of_category).to eq(:examples)
    end

    it "non-formal elements return false" do
      expect(Docbook::Elements::Para.new.formal?).to be false
      expect(Docbook::Elements::Chapter.new.formal?).to be false
    end
  end

  describe "IndexTerm concern" do
    it "IndexTerm returns true for index_term?" do
      expect(Docbook::Elements::IndexTerm.new.index_term?).to be true
    end

    it "non-index elements return false for index_term?" do
      expect(Docbook::Elements::Para.new.index_term?).to be false
      expect(Docbook::Elements::Chapter.new.index_term?).to be false
    end
  end

  describe "Xref protocol" do
    it "Xref returns true for xref?" do
      expect(Docbook::Elements::Xref.new.xref?).to be true
    end

    it "non-xref elements return false for xref?" do
      expect(Docbook::Elements::Para.new.xref?).to be false
      expect(Docbook::Elements::Link.new.xref?).to be false
    end
  end

  describe "CalloutMarker protocol" do
    it "Co returns true for callout_marker?" do
      expect(Docbook::Elements::Co.new.callout_marker?).to be true
    end

    it "non-co elements return false for callout_marker?" do
      expect(Docbook::Elements::Para.new.callout_marker?).to be false
      expect(Docbook::Elements::Emphasis.new.callout_marker?).to be false
    end
  end

  describe "Numberable protocol" do
    it "numberable elements return true for numberable?" do
      expect(Docbook::Elements::Chapter.new.numberable?).to be true
      expect(Docbook::Elements::Section.new.numberable?).to be true
      expect(Docbook::Elements::Part.new.numberable?).to be true
      expect(Docbook::Elements::Appendix.new.numberable?).to be true
    end

    it "non-numberable elements return false for numberable?" do
      expect(Docbook::Elements::Para.new.numberable?).to be false
      expect(Docbook::Elements::Book.new.numberable?).to be false
      expect(Docbook::Elements::Article.new.numberable?).to be false
      expect(Docbook::Elements::Figure.new.numberable?).to be false
    end
  end
end
