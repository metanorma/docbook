# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Services::CollectionManifestResolver do
  let(:fixtures_dir) { "spec/fixtures/library_sample" }

  describe "#resolve" do
    context "with YAML manifest" do
      it "parses the manifest" do
        manifest = described_class.new(File.join(fixtures_dir, "library.yml")).resolve
        expect(manifest.name).to eq("Test Library")
        expect(manifest.books.size).to eq(2)
      end

      it "resolves absolute paths for book sources" do
        manifest = described_class.new(File.join(fixtures_dir, "library.yml")).resolve
        book = manifest.books.first
        expect(book.source).to end_with("book-one/book-one.xml")
        expect(File.exist?(book.source)).to be true
      end

      it "resolves cover paths" do
        manifest = described_class.new(File.join(fixtures_dir, "library.yml")).resolve
        book = manifest.books.find { |b| b.id == "book-one" }
        expect(book.cover).to end_with("book-one/cover.png")
      end
    end

    context "with JSON manifest" do
      it "parses the manifest" do
        manifest = described_class.new(File.join(fixtures_dir, "library.json")).resolve
        expect(manifest.name).to eq("Test Library")
        expect(manifest.books.size).to eq(2)
      end
    end

    context "with directory" do
      it "auto-discovers XML files in subdirectories" do
        manifest = described_class.new(fixtures_dir).resolve
        expect(manifest.books.size).to be >= 2
      end
    end

    context "with non-existent path" do
      it "raises an error" do
        expect {
          described_class.new("/nonexistent/path").resolve
        }.to raise_error(StandardError)
      end
    end
  end
end
