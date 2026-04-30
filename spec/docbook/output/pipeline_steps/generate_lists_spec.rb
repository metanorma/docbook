# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::GenerateLists do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }
  let(:context) do
    ctx = Docbook::Output::PipelineContext.new(xml_path: xml_path)
    Docbook::Output::PipelineSteps::ParseXml.new.call({}, ctx)
    ctx
  end

  it "returns the guide hash" do
    guide = { "toc" => { "numbering" => {} } }
    result = described_class.new.call(guide, context)
    expect(result).to eq(guide)
  end

  it "adds list_of entries for figures, tables, or examples" do
    guide = { "toc" => { "numbering" => {} } }
    described_class.new.call(guide, context)
    has_lists = guide.keys.any? { |k| k.start_with?("list_of_") }
    expect(has_lists).to be true
  end
end
