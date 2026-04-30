# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::AttachMetadata do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }
  let(:context) do
    ctx = Docbook::Output::PipelineContext.new(xml_path: xml_path, title: "Test Title")
    Docbook::Output::PipelineSteps::ParseXml.new.call({}, ctx)
    Docbook::Output::PipelineSteps::GenerateToc.new.call({}, ctx)
    Docbook::Output::PipelineSteps::GenerateNumbering.new.call({}, ctx)
    Docbook::Output::PipelineSteps::TransformMirror.new.call({}, ctx)
    ctx
  end
  let(:prior_guide) do
    guide = {}
    Docbook::Output::PipelineSteps::GenerateToc.new.call(guide, context)
    Docbook::Output::PipelineSteps::GenerateNumbering.new.call(guide, context)
    Docbook::Output::PipelineSteps::TransformMirror.new.call(guide, context)
    guide
  end

  it "moves toc_sections_raw into toc.sections" do
    guide = described_class.new.call(prior_guide.dup, context)
    expect(guide["toc"]).to include("sections")
    expect(guide).not_to have_key("toc_sections_raw")
  end

  it "moves numbering into toc.numbering" do
    guide = described_class.new.call(prior_guide.dup, context)
    expect(guide["toc"]).to include("numbering")
    expect(guide).not_to have_key("numbering")
  end

  it "generates meta with title" do
    guide = described_class.new.call(prior_guide.dup, context)
    expect(guide["meta"]).to include("title")
  end

  it "uses context title as fallback" do
    guide = described_class.new.call(prior_guide.dup, context)
    expect(guide["meta"]["title"]).not_to be_nil
  end
end
