# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::LibraryBuilder do
  let(:manifest_yml) { "spec/fixtures/library_sample/library.yml" }
  let(:manifest_json) { "spec/fixtures/library_sample/library.json" }
  let(:library_dir) { "spec/fixtures/library_sample" }

  shared_examples "a valid library format output" do |format, file_check|
    it "builds #{format} format library successfully" do
      Dir.mktmpdir do |dir|
        output = %i[inline dom].include?(format) ? File.join(dir, "library.html") : File.join(dir, "library")
        result = described_class.new(
          input_path: manifest_yml,
          output_path: output,
          format: format,
          title: "Test Library",
        ).build
        expect(result).to eq(output)
        instance_exec(result, &file_check)
      end
    end
  end

  describe "#build" do
    it_behaves_like "a valid library format output", :inline, ->(path) {
      html = File.read(path)
      expect(html).to include("window.DOCBOOK_COLLECTION")
      expect(html).to include("<style>")
    }

    it_behaves_like "a valid library format output", :dom, ->(path) {
      html = File.read(path)
      expect(html).to include("window.DOCBOOK_COLLECTION")
      expect(html).to include("window.DOCBOOK_FORMAT = 'dom'")
    }

    it_behaves_like "a valid library format output", :dist, ->(dir) {
      expect(File.exist?(File.join(dir, "index.html"))).to be true
      expect(File.exist?(File.join(dir, "data", "book-one.json"))).to be true
      expect(File.exist?(File.join(dir, "data", "book-two.json"))).to be true
    }

    it "builds from JSON manifest" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "library.html")
        result = described_class.new(
          input_path: manifest_json,
          output_path: output,
          format: :inline,
        ).build
        expect(result).to eq(output)
        html = File.read(output)
        expect(html).to include("window.DOCBOOK_COLLECTION")
      end
    end

    it "builds from directory (auto-discovery)" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "library.html")
        result = described_class.new(
          input_path: library_dir,
          output_path: output,
          format: :inline,
        ).build
        expect(result).to eq(output)
        html = File.read(output)
        expect(html).to include("window.DOCBOOK_COLLECTION")
      end
    end

    it "raises on unknown format" do
      expect do
        described_class.new(input_path: manifest_yml, output_path: "/tmp/out.html", format: :unknown).build
      end.to raise_error(ArgumentError, /Unknown format/)
    end
  end
end
