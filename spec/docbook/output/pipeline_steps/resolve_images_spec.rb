# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::PipelineSteps::ResolveImages do
  let(:xml_path) { "spec/fixtures/kitchen-sink/kitchen-sink.xml" }
  let(:context) do
    Docbook::Output::PipelineContext.new(
      xml_path: xml_path,
      image_search_dirs: [],
      image_strategy: :data_url,
    )
  end

  it "returns the guide hash" do
    guide = { "type" => "doc", "content" => [] }
    result = described_class.new.call(guide, context)
    expect(result).to eq(guide)
  end

  it "does not crash on guide with no images" do
    guide = { "type" => "doc", "content" => [] }
    expect { described_class.new.call(guide, context) }.not_to raise_error
  end
end
