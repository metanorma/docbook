# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Formats::LibrarySupport do
  # Create a test host class that includes the concern
  let(:host_class) do
    Class.new(Docbook::Output::Formats::BaseFormat) do
      include Docbook::Output::Formats::LibrarySupport
    end
  end
  let(:instance) { host_class.new }

  describe "#build_collection_data" do
    let(:manifest) do
      Docbook::Models::CollectionManifest.new(
        name: "Test Library",
        description: "A test library",
        books: [
          Docbook::Models::BookEntry.new(id: "book1", source: "/path/book1.xml", title: "Book One"),
          Docbook::Models::BookEntry.new(id: "book2", source: "/path/book2.xml", author: "Jane Doe"),
        ],
      )
    end
    let(:guides) do
      [
        { "type" => "doc", "meta" => { "title" => "First Book" } },
        { "type" => "doc", "meta" => { "title" => "Second Book" } },
      ]
    end

    it "builds a collection data structure with name and books" do
      result = instance.send(:build_collection_data, guides, manifest)
      expect(result["name"]).to eq("Test Library")
      expect(result["description"]).to eq("A test library")
      expect(result["books"].size).to eq(2)
    end

    it "maps book entries with id, title, and data" do
      result = instance.send(:build_collection_data, guides, manifest)
      book = result["books"].first
      expect(book["id"]).to eq("book1")
      expect(book["title"]).to eq("First Book")
      expect(book["data"]).to eq(guides.first)
    end

    it "falls back to book entry title when meta title is absent" do
      guides[1].delete("meta")
      result = instance.send(:build_collection_data, guides, manifest)
      book = result["books"][1]
      # book2 has no title attribute, so falls back to id
      expect(book["title"]).to eq("book2")
    end

    it "uses book entry title when meta is missing" do
      guides[0].delete("meta")
      result = instance.send(:build_collection_data, guides, manifest)
      book = result["books"].first
      # book1 has title "Book One"
      expect(book["title"]).to eq("Book One")
    end
  end

  describe "#resolve_cover" do
    it "returns nil when no cover is configured" do
      book_entry = Docbook::Models::BookEntry.new(id: "book1", source: "/path/book1.xml")
      guide = {}
      result = instance.send(:resolve_cover, book_entry, guide)
      expect(result).to be_nil
    end

    it "returns data URL when cover file exists" do
      Dir.mktmpdir do |dir|
        cover_path = File.join(dir, "cover.png")
        File.binwrite(cover_path, "\x89PNG\r\n\x1a\n#{"\x00" * 100}")

        book_entry = Docbook::Models::BookEntry.new(
          id: "book1", source: File.join(dir, "book1.xml"), cover: cover_path,
        )
        guide = {}
        result = instance.send(:resolve_cover, book_entry, guide)
        expect(result).to start_with("data:image/png;base64,")
      end
    end

    it "falls back to XML meta cover when book entry has no cover" do
      Dir.mktmpdir do |dir|
        xml_path = File.join(dir, "book1.xml")
        File.write(xml_path, "<article/>")

        cover_path = File.join(dir, "mycover.png")
        File.binwrite(cover_path, "\x89PNG\r\n\x1a\n#{"\x00" * 100}")

        book_entry = Docbook::Models::BookEntry.new(id: "book1", source: xml_path)
        guide = { "meta" => { "cover" => "mycover.png" } }
        result = instance.send(:resolve_cover, book_entry, guide)
        expect(result).to start_with("data:image/png;base64,")
      end
    end

    it "returns nil when meta cover file does not exist" do
      book_entry = Docbook::Models::BookEntry.new(id: "book1", source: "/nonexistent/book1.xml")
      guide = { "meta" => { "cover" => "missing.png" } }
      result = instance.send(:resolve_cover, book_entry, guide)
      expect(result).to be_nil
    end
  end
end
