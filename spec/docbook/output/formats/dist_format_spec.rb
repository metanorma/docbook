# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Formats::DistFormat do
  let(:format) { described_class.new }
  let(:guide) { { "type" => "doc", "content" => [] } }

  it "creates directory with index.html and data/book.json" do
    Dir.mktmpdir do |dir|
      format.write(File.join(dir, "index.html"), guide, title: "Test")
      expect(File.exist?(File.join(dir, "index.html"))).to be true
      expect(File.exist?(File.join(dir, "data", "book.json"))).to be true
    end
  end

  it "sets DOCBOOK_DATA_SOURCE in index.html" do
    Dir.mktmpdir do |dir|
      format.write(File.join(dir, "index.html"), guide, title: "Test")
      html = File.read(File.join(dir, "index.html"))
      expect(html).to include("window.DOCBOOK_DATA_SOURCE = 'data/book.json'")
      expect(html).to include("window.DOCBOOK_FORMAT = 'dist'")
    end
  end

  it "writes valid JSON to data/book.json" do
    Dir.mktmpdir do |dir|
      format.write(File.join(dir, "index.html"), guide, title: "Test")
      data = JSON.parse(File.read(File.join(dir, "data", "book.json")))
      expect(data["type"]).to eq("doc")
    end
  end

  it "returns the directory path" do
    Dir.mktmpdir do |dir|
      result = format.write(File.join(dir, "index.html"), guide, title: "Test")
      expect(result).to eq(dir)
    end
  end
end
