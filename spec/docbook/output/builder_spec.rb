# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Builder do
  let(:xml_path) { "spec/fixtures/article/article.xml" }

  shared_examples "a valid format output" do |format, file_check|
    it "builds #{format} format successfully" do
      Dir.mktmpdir do |dir|
        output = format == :inline || format == :dom ? File.join(dir, "output.html") : File.join(dir, "output")
        result = described_class.new(
          xml_path: xml_path,
          output_path: output,
          format: format,
          title: "Test",
        ).build
        expect(result).to eq(output)
        instance_exec(result, &file_check)
      end
    end
  end

  describe "#build" do
    include_examples "a valid format output", :inline, ->(path) {
      html = File.read(path)
      expect(html).to include("window.DOCBOOK_DATA")
      expect(html).to include("<style>")
    }

    include_examples "a valid format output", :dom, ->(path) {
      html = File.read(path)
      expect(html).to include('id="docbook-content"')
      expect(html).to include("window.DOCBOOK_FORMAT = 'dom'")
    }

    include_examples "a valid format output", :dist, ->(dir) {
      expect(File.exist?(File.join(dir, "index.html"))).to be true
      expect(File.exist?(File.join(dir, "data", "book.json"))).to be true
      data = JSON.parse(File.read(File.join(dir, "data", "book.json")))
      expect(data["type"]).to eq("doc")
    }

    include_examples "a valid format output", :paged, ->(dir) {
      expect(File.exist?(File.join(dir, "index.html"))).to be true
      pages = Dir.glob(File.join(dir, "pages", "*.html"))
      expect(pages).not_to be_empty
    }

    it "raises on unknown format" do
      expect {
        described_class.new(xml_path: xml_path, output_path: "/tmp/out.html", format: :unknown).build
      }.to raise_error(ArgumentError, /Unknown format/)
    end
  end
end
