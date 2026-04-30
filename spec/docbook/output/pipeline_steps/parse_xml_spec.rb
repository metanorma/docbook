# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::ParseXml do
  let(:xml_path) { "spec/fixtures/article/article.xml" }
  let(:context) { Docbook::Output::PipelineContext.new(xml_path: xml_path) }

  it "parses XML and sets context.parsed" do
    described_class.new.call({}, context)
    expect(context.parsed).to be_a(Docbook::Elements::Article)
  end

  it "returns the guide hash" do
    guide = described_class.new.call({}, context)
    expect(guide).to eq({})
  end

  it "parses document content" do
    described_class.new.call({}, context)
    doc = context.parsed
    expect(doc.para).not_to be_empty
  end
end
