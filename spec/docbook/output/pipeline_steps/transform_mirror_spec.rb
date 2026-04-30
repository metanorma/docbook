# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::TransformMirror do
  let(:xml_path) { "spec/fixtures/article/article.xml" }
  let(:context) do
    ctx = Docbook::Output::PipelineContext.new(xml_path: xml_path)
    Docbook::Output::PipelineSteps::ParseXml.new.call({}, ctx)
    ctx
  end

  it "merges mirror data into the guide" do
    guide = described_class.new.call({}, context)
    expect(guide).to have_key("type")
    expect(guide["type"]).to eq("doc")
  end

  it "includes content array from mirror" do
    guide = described_class.new.call({}, context)
    expect(guide["content"]).to be_an(Array)
    expect(guide["content"]).not_to be_empty
  end
end
