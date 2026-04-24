# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Formats::PagedFormat do
  let(:format) { described_class.new }

  it "creates directory with index.html and pages" do
    guide = Docbook::Output::Pipeline.new(
      xml_path: "spec/fixtures/kitchen-sink/kitchen-sink.xml",
    ).process

    Dir.mktmpdir do |dir|
      format.write(File.join(dir, "index.html"), guide, title: "Test")
      expect(File.exist?(File.join(dir, "index.html"))).to be true
      pages = Dir.glob(File.join(dir, "pages", "*.html"))
      expect(pages.size).to be >= 2
    end
  end

  it "includes page map and TOC in index.html" do
    guide = Docbook::Output::Pipeline.new(
      xml_path: "spec/fixtures/kitchen-sink/kitchen-sink.xml",
    ).process

    Dir.mktmpdir do |dir|
      format.write(File.join(dir, "index.html"), guide, title: "Test")
      html = File.read(File.join(dir, "index.html"))
      expect(html).to include("window.DOCBOOK_PAGES")
      expect(html).to include("window.DOCBOOK_TOC")
      expect(html).to include("window.DOCBOOK_FORMAT = 'paged'")
    end
  end

  it "each page contains content" do
    guide = Docbook::Output::Pipeline.new(
      xml_path: "spec/fixtures/kitchen-sink/kitchen-sink.xml",
    ).process

    Dir.mktmpdir do |dir|
      format.write(File.join(dir, "index.html"), guide, title: "Test")
      pages = Dir.glob(File.join(dir, "pages", "*.html"))
      pages.each do |page|
        html = File.read(page)
        expect(html).to include("<!DOCTYPE html>")
        expect(html).to include("window.DOCBOOK_FORMAT = 'paged'")
      end
    end
  end
end
