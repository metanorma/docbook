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

  describe "composability" do
    let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }

    it "accepts a custom step list with only parse + mirror" do
      steps = [
        Docbook::Output::PipelineSteps::ParseXml,
        Docbook::Output::PipelineSteps::TransformMirror,
      ]
      guide = described_class.new(xml_path: xml_path, steps: steps).process

      expect(guide["type"]).to eq("doc")
      expect(guide["content"]).to be_an(Array)
      expect(guide["content"]).not_to be_empty
      # No TOC, numbering, or index since those steps were skipped
      expect(guide).not_to have_key("toc")
      expect(guide).not_to have_key("index")
    end

    it "allows injecting a custom step" do
      custom_data = nil
      custom_step = Class.new do
        define_method(:call) do |guide, _context|
          guide["custom_marker"] = true
          custom_data = guide
          guide
        end
      end

      steps = described_class::DEFAULT_STEPS.dup
      steps.insert(5, custom_step)

      guide = described_class.new(xml_path: xml_path, steps: steps).process
      expect(guide["custom_marker"]).to be(true)
    end

    it "allows reordering steps" do
      # Reorder: parse, mirror, then metadata (skip toc/numbering/index steps)
      steps = [
        Docbook::Output::PipelineSteps::ParseXml,
        Docbook::Output::PipelineSteps::TransformMirror,
        Docbook::Output::PipelineSteps::AttachMetadata,
      ]
      guide = described_class.new(xml_path: xml_path, steps: steps).process

      expect(guide["meta"]).to include("title")
      expect(guide["type"]).to eq("doc")
    end

    it "exposes steps and context for introspection" do
      pipeline = described_class.new(xml_path: xml_path)
      expect(pipeline.steps).to eq(described_class::DEFAULT_STEPS)
      expect(pipeline.context).to be_a(Docbook::Output::PipelineContext)
      expect(pipeline.context.xml_path).to eq(xml_path)
    end
  end
end
