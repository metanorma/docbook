# frozen_string_literal: true

require "spec_helper"
require "docbook/cli"
require "tempfile"

FRONTEND_DIST = File.expand_path("../../frontend/dist", __dir__)

def frontend_built?
  File.exist?(File.join(FRONTEND_DIST, "app.css"))
end

RSpec.describe Docbook::CLI do
  let(:sample_xml) do
    File.read("spec/fixtures/xslTNG/guide/xml/examples/sample.xml")
  end

  # Build tests require frontend dist artifacts (app.css, app.iife.js).
  # Skip on CI where frontend is not built.

  describe "build" do
    let(:guide_xml) { "spec/fixtures/xslTNG/guide/xml/guide.xml" }

    it "builds an interactive HTML reader", if: frontend_built? do
      Tempfile.create(["test", ".html"]) do |out|
        expect do
          described_class.start(["build", guide_xml, "-o",
                                 out.path])
        end.to output(/Built/).to_stdout
        content = File.read(out.path)
        expect(content).to include("<!DOCTYPE html>")
        expect(content).to include("window.DOCBOOK_DATA")
      end
    end

    it "derives output path from input when -o is omitted", if: frontend_built? do
      input = File.expand_path(guide_xml)
      expected_output = input.sub(/\.xml$/, ".html")

      expect do
        described_class.start(["build", input])
      end.to output(/Built/).to_stdout
      expect(File.exist?(expected_output)).to be true
      FileUtils.rm_f(expected_output)
    end

    it "builds from --demo fixture (default xslTNG)", if: frontend_built? do
      Tempfile.create(["demo", ".html"]) do |out|
        expect do
          described_class.start(["build", "--demo", "-o",
                                 out.path])
        end.to output(/Built/).to_stdout
        content = File.read(out.path)
        expect(content).to include("<!DOCTYPE html>")
        expect(content).to include("window.DOCBOOK_DATA")
      end
    end

    it "builds from --demo=model-flow fixture", if: frontend_built? do
      Tempfile.create(["demo", ".html"]) do |out|
        expect do
          described_class.start(["build", "--demo=model-flow", "-o",
                                 out.path])
        end.to output(/Built/).to_stdout
        content = File.read(out.path)
        expect(content).to include("<!DOCTYPE html>")
        expect(content).to include("Art of the Model Flow")
      end
    end

    it "rejects unknown demo name" do
      expect do
        described_class.start(["build", "--demo=nonexistent", "-o",
                               "/tmp/test.html"])
      end.to raise_error(Docbook::CliError, /Unknown demo/)
    end
  end

  describe "validate" do
    it "validates well-formed XML" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["validate", f.path])
        end.to output(/valid/).to_stdout
      end
    end

    it "validates against RELAX NG schema by default" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["validate", f.path])
        end.to output(/valid/).to_stdout
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
        expect do
          described_class.start(["validate", f.path])
        end.to raise_error(Docbook::ValidationError)
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
        expect do
          described_class.start(["validate", "--wellformed",
                                 f.path])
        end.to output(/valid/).to_stdout
      end
    end
  end

  describe "format" do
    it "formats DocBook XML" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["format", f.path])
        end.to output(/<article/).to_stdout
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

  describe "build --verbose" do
    let(:guide_xml) { "spec/fixtures/xslTNG/guide/xml/guide.xml" }

    it "shows detailed output with --verbose", if: frontend_built? do
      Tempfile.create(["test", ".html"]) do |out|
        expect do
          described_class.start(["build", guide_xml, "-o", out.path, "--verbose"])
        end.to output(/Parsing guide\.xml/).to_stdout
        expect(File.read(out.path)).to include("<!DOCTYPE html>")
      end
    end

    it "suppresses output with --quiet", if: frontend_built? do
      Tempfile.create(["test", ".html"]) do |out|
        expect do
          described_class.start(["build", guide_xml, "-o", out.path, "--quiet"])
        end.not_to output.to_stdout
        expect(File.exist?(out.path)).to be true
      end
    end
  end

  describe "info --format=json" do
    let(:guide_xml) { "spec/fixtures/xslTNG/guide/xml/guide.xml" }

    it "outputs JSON with --format=json" do
      expect do
        described_class.start(["info", guide_xml, "--format=json"])
      end.to output(/"title"/).to_stdout
    end

    it "outputs text by default" do
      expect do
        described_class.start(["info", guide_xml])
      end.to output(/Title:/).to_stdout
    end
  end

  describe "validate --verbose" do
    it "shows detailed checks with --verbose" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["validate", f.path, "--verbose"])
        end.to output(/Well-formedness: OK/).to_stdout
      end
    end
  end

  describe "lint" do
    it "reports ok for valid documents" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["lint", f.path])
        end.to output(/: ok/).to_stdout
      end
    end

    it "reports ok for the guide fixture" do
      expect do
        described_class.start(["lint", "spec/fixtures/xslTNG/guide/xml/guide.xml"])
      end.to output(/: ok/).to_stdout
    end

    it "detects well-formedness errors" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write("<bad><xml")
        f.flush
        expect do
          described_class.start(["lint", f.path])
        end.to raise_error(Docbook::ValidationError)
      end
    end

    it "detects duplicate IDs" do
      dup_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.0">
          <title>Test</title>
          <chapter xml:id="dup"><title>A</title><para>text</para></chapter>
          <chapter xml:id="dup"><title>B</title><para>text</para></chapter>
        </book>
      XML
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(dup_xml)
        f.flush
        # Nokogiri catches duplicate IDs at the well-formedness level
        expect do
          described_class.start(["lint", f.path])
        end.to raise_error(Docbook::ValidationError, /already defined/)
      end
    end

    it "detects broken xrefs with --strict" do
      broken_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <book xmlns="http://docbook.org/ns/docbook" version="5.0">
          <title>Test</title>
          <chapter xml:id="ch1"><title>A</title><para>See <xref linkend="nonexistent"/>.</para></chapter>
        </book>
      XML
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(broken_xml)
        f.flush
        expect do
          described_class.start(["lint", f.path, "--strict"])
        end.to raise_error(Docbook::LintError, /Broken xref/)
      end
    end

    it "shows verbose output" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["lint", f.path, "--verbose"])
        end.to output(/Well-formedness: OK/).to_stdout
      end
    end
  end

  describe "format XInclude warning" do
    it "warns when XIncludes detected but not resolved" do
      xinclude_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <book xmlns="http://docbook.org/ns/docbook"
              xmlns:xi="http://www.w3.org/2001/XInclude" version="5.0">
          <title>Test</title>
          <xi:include href="chapter1.xml"/>
        </book>
      XML
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(xinclude_xml)
        f.flush
        expect do
          described_class.start(["format", f.path])
        end.to output(/contains XIncludes/).to_stderr
      end
    end
  end

  describe "roundtrip" do
    it "round-trips valid DocBook files" do
      Tempfile.create(["test", ".xml"]) do |f|
        f.write(sample_xml)
        f.flush
        expect do
          described_class.start(["roundtrip", f.path])
        end.to output(/OK/).to_stdout
      end
    end
  end
end
