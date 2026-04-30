# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::GenerateNumbering do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }
  let(:context) do
    ctx = Docbook::Output::PipelineContext.new(xml_path: xml_path)
    Docbook::Output::PipelineSteps::ParseXml.new.call({}, ctx)
    ctx
  end

  it "populates numbering in the guide" do
    guide = described_class.new.call({}, context)
    expect(guide).to have_key("numbering")
  end

  it "returns a hash mapping IDs to numbers" do
    guide = described_class.new.call({}, context)
    numbering = guide["numbering"]
    expect(numbering).to be_a(Hash)
    expect(numbering).not_to be_empty
  end
end
