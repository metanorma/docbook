# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Services::DocumentStats, "#generate" do
  let(:article_stats) do
    parsed = Docbook::Document.from_xml(File.read("spec/fixtures/article/article.xml"))
    described_class.new(parsed).generate
  end

  describe "metadata extraction" do
    it "extracts title" do
      expect(article_stats["title"]).to eq("A Test Article")
    end

    it "extracts subtitle" do
      expect(article_stats["subtitle"]).to eq("Article-Type Document Fixture")
    end

    it "extracts author name" do
      expect(article_stats["author"]).to eq("Test Author")
    end

    it "extracts pubdate" do
      expect(article_stats["pubdate"]).to eq("2026-03-01")
    end

    it "identifies root element type" do
      expect(article_stats["root_element"]).to eq("article")
    end

    it "returns nil cover when no <cover> element" do
      expect(article_stats["cover"]).to be_nil
    end
  end

  describe "element counting" do
    it "counts sections" do
      expect(article_stats["sections"]).to be > 0
    end

    it "counts code blocks" do
      expect(article_stats["code_blocks"]).to be >= 1
    end

    it "counts tables" do
      expect(article_stats["tables"]).to be >= 1
    end
  end

  describe "cover extraction" do
    it "extracts cover from <info>" do
      parsed = Docbook::Document.from_xml(File.read("spec/fixtures/xslTNG/test/resources/xml/book.014.xml"))
      stats = described_class.new(parsed).generate
      expect(stats["cover"]).to eq("../media/yoyodyne.png")
    end
  end
end
