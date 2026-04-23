# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Formats::DomFormat do
  let(:format) { described_class.new }

  it "writes a single HTML with pre-rendered content" do
    guide = Docbook::Output::Pipeline.new(
      xml_path: "spec/fixtures/article/article.xml"
    ).process

    Dir.mktmpdir do |dir|
      path = File.join(dir, "output.html")
      format.write(path, guide, title: "Test")
      html = File.read(path)
      expect(html).to include('id="docbook-content"')
      expect(html).to include("<p class=\"db-paragraph\">")
      expect(html).to include("window.DOCBOOK_FORMAT = 'dom'")
    end
  end

  it "includes JSON data for TOC and search" do
    guide = Docbook::Output::Pipeline.new(
      xml_path: "spec/fixtures/article/article.xml"
    ).process

    Dir.mktmpdir do |dir|
      path = File.join(dir, "output.html")
      format.write(path, guide, title: "Test")
      html = File.read(path)
      expect(html).to include("window.DOCBOOK_DATA")
    end
  end
end
