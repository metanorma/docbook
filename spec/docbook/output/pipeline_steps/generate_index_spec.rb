# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::GenerateIndex do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }
  let(:context) do
    ctx = Docbook::Output::PipelineContext.new(xml_path: xml_path)
    Docbook::Output::PipelineSteps::ParseXml.new.call({}, ctx)
    ctx
  end

  it "populates index_data in the guide" do
    guide = described_class.new.call({}, context)
    expect(guide).to have_key("index_data")
  end

  it "index_data has title and groups" do
    guide = described_class.new.call({}, context)
    index = guide["index_data"]
    expect(index).to include("title" => "Index", "type" => "index")
    expect(index).to have_key("groups")
  end
end
