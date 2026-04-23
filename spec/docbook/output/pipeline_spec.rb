# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::Pipeline do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }

  describe "#process" do
    subject(:guide) { described_class.new(xml_path: xml_path).process }

    it "returns a hash with type doc" do
      expect(guide).to include("type" => "doc")
    end

    it "includes content array" do
      expect(guide["content"]).to be_an(Array)
      expect(guide["content"]).not_to be_empty
    end

    it "includes toc with sections and numbering" do
      expect(guide["toc"]).to include("sections", "numbering")
      expect(guide["toc"]["sections"]).to be_an(Array)
    end

    it "includes index data" do
      expect(guide).to include("index")
    end

    it "includes meta with title" do
      expect(guide["meta"]).to include("title", "root_element")
    end

    it "has numbering entries" do
      numbering = guide.dig("toc", "numbering")
      expect(numbering).to be_a(Hash)
    end
  end

  context "with article fixture" do
    let(:xml_path) { "spec/fixtures/article/article.xml" }

    it "processes an article document" do
      guide = described_class.new(xml_path: xml_path).process
      expect(guide["type"]).to eq("doc")
      expect(guide["content"]).to be_an(Array)
    end
  end
end
