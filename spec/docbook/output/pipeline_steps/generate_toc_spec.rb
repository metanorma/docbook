# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::GenerateToc do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }
  let(:context) do
    ctx = Docbook::Output::PipelineContext.new(xml_path: xml_path)
    Docbook::Output::PipelineSteps::ParseXml.new.call({}, ctx)
    ctx
  end

  it "populates toc_sections_raw in the guide" do
    guide = described_class.new.call({}, context)
    expect(guide).to have_key("toc_sections_raw")
  end

  it "generates TOC entries as an array" do
    guide = described_class.new.call({}, context)
    sections = guide["toc_sections_raw"]
    expect(sections).to be_an(Array)
    expect(sections).not_to be_empty
  end

  it "includes id and title in TOC entries" do
    guide = described_class.new.call({}, context)
    first = guide["toc_sections_raw"].first
    expect(first).to include("id", "title")
  end
end
