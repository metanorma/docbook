# frozen_string_literal: true

require "spec_helper"
require "docbook/cli"
require "tempfile"

RSpec.describe Docbook::CLI do
  let(:sample_xml) { File.read("spec/fixtures/xslTNG/guide/xml/examples/sample.xml") }

  describe "validate" do
    it "validates well-formed XML" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect { described_class.start(["validate", f.path]) }.to output(/valid/).to_stdout
      end
    end

    it "validates against RELAX NG schema by default" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect { described_class.start(["validate", f.path]) }.to output(/valid/).to_stdout
      end
    end

    it "detects schema errors" do
      invalid_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.0">
          <title>Test</title>
          <badtag>Not valid DocBook</badtag>
        </article>
      XML
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(invalid_xml)
        f.flush
        expect { described_class.start(["validate", f.path]) }.to raise_error(SystemExit)
      end
    end

    it "skips schema validation with --wellformed" do
      invalid_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <article xmlns="http://docbook.org/ns/docbook" version="5.0">
          <title>Test</title>
          <badtag>Not valid DocBook</badtag>
        </article>
      XML
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(invalid_xml)
        f.flush
        expect { described_class.start(["validate", "--wellformed", f.path]) }.to output(/valid/).to_stdout
      end
    end
  end

  describe "format" do
    it "formats DocBook XML" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect { described_class.start(["format", f.path]) }.to output(/<article/).to_stdout
      end
    end

    it "writes to output file" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        Tempfile.create(["out", ".xml"]) do |out|
          described_class.start(["format", f.path, "-o", out.path])
          expect(File.read(out.path)).to include("<article")
        end
      end
    end
  end

  describe "to-html" do
    it "converts to HTML" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect { described_class.start(["to-html", f.path]) }.to output(/<!DOCTYPE html>/).to_stdout
      end
    end
  end

  describe "roundtrip" do
    it "round-trips valid DocBook files" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect { described_class.start(["roundtrip", f.path]) }.to output(/OK/).to_stdout
      end
    end
  end
end
