# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "json"

RSpec.describe Docbook::Output::Formats::ChunkedFormat do
  let(:format) { described_class.new }

  let(:guide) do
    {
      "meta" => { "title" => "Test Book", "author" => "Jane Doe" },
      "toc" => {
        "sections" => [
          { "id" => "intro", "title" => "Introduction" },
          { "id" => "ch1", "title" => "Chapter 1" },
          { "id" => "app-a", "title" => "Appendix A" },
        ],
        "numbering" => { "intro" => "", "ch1" => "1", "app-a" => "A" },
      },
      "content" => [
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Preface text." }] },
        { "type" => "chapter", "attrs" => { "xml_id" => "intro", "title" => "Introduction" },
          "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Intro." }] }] },
        { "type" => "section", "attrs" => { "xml_id" => "ch1", "title" => "Chapter 1" },
          "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Chapter text." }] }] },
        { "type" => "appendix", "attrs" => { "xml_id" => "app-a", "title" => "Appendix A" },
          "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Appendix text." }] }] },
      ],
    }
  end

  describe "#write" do
    it "creates index.html, manifest.json, and section JSON files" do
      Dir.mktmpdir do |dir|
        output_dir = File.join(dir, "output")
        format.write(output_dir, guide, title: "Test Book")

        expect(File.exist?(File.join(output_dir, "index.html"))).to be true
        expect(File.exist?(File.join(output_dir, "manifest.json"))).to be true
        expect(Dir.exist?(File.join(output_dir, "sections"))).to be true
      end
    end

    it "writes a manifest with metadata and section IDs" do
      Dir.mktmpdir do |dir|
        format.write(File.join(dir, "output"), guide, title: "Test Book")

        manifest = JSON.parse(File.read(File.join(dir, "output", "manifest.json")))
        expect(manifest["meta"]["title"]).to eq("Test Book")
        # Leading paragraph creates a "chunk-1" entry before the sections
        expect(manifest["total_sections"]).to eq(4)
        expect(manifest["section_ids"][0]).to start_with("chunk-")
        expect(manifest["section_ids"][1..]).to eq(%w[intro ch1 app-a])
        expect(manifest["toc"]["sections"].size).to eq(3)
      end
    end

    it "writes individual section files with content and navigation" do
      Dir.mktmpdir do |dir|
        format.write(File.join(dir, "output"), guide, title: "Test Book")

        section = JSON.parse(File.read(File.join(dir, "output", "sections", "ch1.json")))
        expect(section["id"]).to eq("ch1")
        expect(section["content"]).to be_an(Array)
        expect(section["content"].first["type"]).to eq("section")
        expect(section["next"]).to eq("app-a")
        expect(section["prev"]).to eq("intro")
      end
    end

    it "sets next to nil for last section" do
      Dir.mktmpdir do |dir|
        format.write(File.join(dir, "output"), guide, title: "Test Book")

        section = JSON.parse(File.read(File.join(dir, "output", "sections", "app-a.json")))
        expect(section["next"]).to be_nil
        expect(section["prev"]).to eq("ch1")
      end
    end

    it "sets prev to nil for first section" do
      Dir.mktmpdir do |dir|
        format.write(File.join(dir, "output"), guide, title: "Test Book")

        # First chunk is the leading paragraph (chunk-1)
        section = JSON.parse(File.read(File.join(dir, "output", "sections", "chunk-1.json")))
        expect(section["prev"]).to be_nil
        expect(section["next"]).to eq("intro")
      end
    end

    it "handles content with no sections gracefully" do
      minimal_guide = {
        "meta" => {},
        "toc" => { "sections" => [] },
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Just a paragraph." }] },
        ],
      }
      Dir.mktmpdir do |dir|
        format.write(File.join(dir, "output"), minimal_guide, title: "Minimal")

        manifest = JSON.parse(File.read(File.join(dir, "output", "manifest.json")))
        expect(manifest["total_sections"]).to eq(1)
        expect(manifest["section_ids"].first).to start_with("chunk-")
      end
    end

    it "produces valid HTML with chunked format script" do
      Dir.mktmpdir do |dir|
        format.write(File.join(dir, "output"), guide, title: "Test Book")

        html = File.read(File.join(dir, "output", "index.html"))
        expect(html).to include("window.DOCBOOK_FORMAT = 'chunked'")
        expect(html).to include("window.DOCBOOK_MANIFEST = 'manifest.json'")
        expect(html).to include("<!DOCTYPE html>")
      end
    end

    it "is registered in FORMAT_MAP" do
      expect(Docbook::Output::Formats::FORMAT_MAP[:chunked]).to eq(described_class)
    end
  end
end
