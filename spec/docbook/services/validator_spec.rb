# frozen_string_literal: true

RSpec.describe Docbook::Services::Validator do
  let(:sample_xml) do
    <<~XML
      <book xmlns="http://docbook.org/ns/docbook">
        <title>Test</title>
        <chapter><title>Ch1</title><para>Hello</para></chapter>
      </book>
    XML
  end

  let(:malformed_xml) { "<book><title>Broken" }

  let(:input_path) do
    require "tempfile"
    file = Tempfile.new(["validator_test", ".xml"])
    file.write(sample_xml)
    file.close
    file.path
  end

  let(:malformed_path) do
    require "tempfile"
    file = Tempfile.new(["validator_malformed", ".xml"])
    file.write(malformed_xml)
    file.close
    file.path
  end

  after do
    File.delete(input_path) if input_path && File.exist?(input_path)
    File.delete(malformed_path) if malformed_path && File.exist?(malformed_path)
  end

  describe "#check_wellformedness" do
    it "returns valid for well-formed XML" do
      result = described_class.new(input_path: input_path).check_wellformedness
      expect(result.valid?).to be true
      expect(result.errors).to be_empty
    end

    it "returns invalid for malformed XML" do
      result = described_class.new(input_path: malformed_path).check_wellformedness
      expect(result.valid?).to be false
      expect(result.errors).not_to be_empty
    end
  end

  describe "#validate" do
    it "returns valid result for well-formed XML" do
      result = described_class.new(input_path: input_path).validate
      expect(result).to be_a(Struct)
    end
  end
end
