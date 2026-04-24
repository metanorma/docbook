# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Services::DocumentStats, "#generate" do
  it "extracts cover from <info>" do
    parsed = Docbook::Document.from_xml(File.read("spec/fixtures/xslTNG/test/resources/xml/book.014.xml"))
    stats = described_class.new(parsed).generate
    expect(stats["cover"]).to eq("../media/yoyodyne.png")
  end

  it "returns nil cover when no <cover> element" do
    parsed = Docbook::Document.from_xml(File.read("spec/fixtures/article/article.xml"))
    stats = described_class.new(parsed).generate
    expect(stats["cover"]).to be_nil
  end
end
