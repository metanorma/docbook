# frozen_string_literal: true

RSpec.describe Docbook::Services::Formatter do
  let(:sample_xml) do
    <<~XML
      <book xmlns="http://docbook.org/ns/docbook">
        <title>Test Book</title>
        <chapter xml:id="ch1">
          <title>Chapter One</title>
          <para>Hello world</para>
        </chapter>
      </book>
    XML
  end

  let(:input_path) do
    require "tempfile"
    file = Tempfile.new(["formatter_test", ".xml"])
    file.write(sample_xml)
    file.close
    file.path
  end

  after do
    File.delete(input_path) if input_path && File.exist?(input_path)
  end

  describe "#format" do
    it "returns pretty-printed XML" do
      result = described_class.new(input_path: input_path).format
      expect(result).to include("<?xml")
      expect(result).to include("<book")
      expect(result).to include("Chapter One")
    end

    it "preserves document content" do
      result = described_class.new(input_path: input_path).format
      parsed = Docbook::Document.from_xml(result)
      expect(parsed).not_to be_nil
    end

    it "outputs UTF-8 encoding declaration" do
      result = described_class.new(input_path: input_path).format
      expect(result).to include('encoding="utf-8"')
    end
  end
end
