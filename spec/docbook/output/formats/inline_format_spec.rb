# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Formats::InlineFormat do
  let(:format) { described_class.new }
  let(:guide) { { "type" => "doc", "content" => [] } }

  it "writes a single HTML file with inlined data" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "output.html")
      format.write(path, guide, title: "Test Book")
      html = File.read(path)
      expect(html).to include("window.DOCBOOK_DATA")
      expect(html).to include("<style>")
      expect(html).to include("<title>Test Book</title>")
    end
  end

  it "returns the output path" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "output.html")
      result = format.write(path, guide, title: "Test")
      expect(result).to eq(path)
    end
  end
end
