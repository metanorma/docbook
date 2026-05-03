# frozen_string_literal: true

require "spec_helper"
require "docbook/services/linter"

RSpec.describe Docbook::Services::Linter do
  let(:xml) { <<~XML }
    <book xmlns="http://docbook.org/ns/docbook" xml:id="book1">
      <title>Test Book</title>
      <chapter xml:id="ch1">
        <title>Chapter One</title>
        <para>Hello world</para>
      </chapter>
    </book>
  XML

  let(:document) { Docbook::Document.from_xml(xml) }
  let(:linter) { described_class.new(document) }

  describe "#check" do
    it "returns self for chaining" do
      expect(linter.check).to eq(linter)
    end

    it "reports no errors for a valid document" do
      linter.check
      expect(linter.ok?).to be true
      expect(linter.errors).to be_empty
    end
  end

  describe "#ok?" do
    it "returns true when no errors" do
      linter.check
      expect(linter.ok?).to be true
    end
  end

  context "with empty section" do
    let(:xml) { <<~XML }
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="empty-ch">
          <title>Empty Chapter</title>
        </chapter>
      </book>
    XML

    it "reports empty element warnings" do
      linter.check
      expect(linter.warnings).not_to be_empty
      expect(linter.warnings.any? do |w|
        w[:message].include?("Empty")
      end).to be true
    end
  end

  context "with broken xrefs (strict mode)" do
    let(:xml) { <<~XML }
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="ch1">
          <title>Chapter</title>
          <para>See <xref linkend="nonexistent"/>.</para>
        </chapter>
      </book>
    XML

    it "detects broken xrefs in strict mode" do
      linter.check(strict: true)
      expect(linter.errors).not_to be_empty
      expect(linter.errors.any? do |e|
        e[:message].include?("Broken xref")
      end).to be true
    end

    it "does not check xrefs in non-strict mode" do
      linter.check(strict: false)
      xref_errors = linter.errors.select do |e|
        e[:message].include?("Broken xref")
      end
      expect(xref_errors).to be_empty
    end
  end

  context "walk_children integration" do
    it "walks nested elements correctly" do
      xml = <<~XML
        <book xmlns="http://docbook.org/ns/docbook">
          <chapter xml:id="ch1">
            <title>Chapter</title>
            <section xml:id="s1">
              <title>Section</title>
              <para>Content</para>
            </section>
          </chapter>
        </book>
      XML
      doc = Docbook::Document.from_xml(xml)
      lint = described_class.new(doc)
      lint.check
      expect(lint.errors).to be_empty
    end
  end

  context "with duplicate xml:ids" do
    let(:xml) { <<~XML }
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="dup-id">
          <title>First</title>
          <para>A</para>
        </chapter>
        <chapter xml:id="dup-id">
          <title>Second</title>
          <para>B</para>
        </chapter>
      </book>
    XML

    it "detects duplicate IDs" do
      linter.check(strict: true)
      dup_errors = linter.errors.select do |e|
        e[:message].include?("Duplicate")
      end
      expect(dup_errors).not_to be_empty
    end
  end

  context "with valid xrefs" do
    let(:xml) { <<~XML }
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="ch1">
          <title>Chapter</title>
          <para>See <xref linkend="ch1"/>.</para>
        </chapter>
      </book>
    XML

    it "does not report errors for valid xrefs" do
      linter.check(strict: true)
      xref_errors = linter.errors.select { |e| e[:message].include?("xref") }
      expect(xref_errors).to be_empty
    end
  end

  context "with multiple broken xrefs" do
    let(:xml) { <<~XML }
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="ch1">
          <title>Chapter</title>
          <para>See <xref linkend="missing1"/> and <xref linkend="missing2"/>.</para>
        </chapter>
      </book>
    XML

    it "reports each broken xref separately" do
      linter.check(strict: true)
      xref_errors = linter.errors.select do |e|
        e[:message].include?("Broken xref")
      end
      expect(xref_errors.length).to be >= 2
    end
  end
end
