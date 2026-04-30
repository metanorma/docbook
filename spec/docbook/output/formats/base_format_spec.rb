# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Docbook::Output::Formats::BaseFormat do
  after do
    described_class.configured_dist_dir = nil
  end

  describe ".default_dist_dir" do
    it "returns the built-in default" do
      expect(described_class.default_dist_dir).to eq(described_class::DEFAULT_DIST_DIR)
    end

    it "returns the configured override when set" do
      described_class.configured_dist_dir = "/custom/path"
      expect(described_class.default_dist_dir).to eq("/custom/path")
    end
  end

  describe "#initialize" do
    it "uses default_dist_dir when no dist_dir given" do
      instance = described_class.new
      expect(instance.dist_dir).to eq(described_class.default_dist_dir)
    end

    it "uses the provided dist_dir when given" do
      instance = described_class.new(dist_dir: "/my/custom/dir")
      expect(instance.dist_dir).to eq("/my/custom/dir")
    end
  end

  describe "#dist_assets" do
    it "raises ArgumentError when dist directory does not exist" do
      instance = described_class.new(dist_dir: "/nonexistent/path")
      expect { instance.send(:dist_assets) }.to raise_error(ArgumentError, /Frontend dist directory not found/)
    end

    it "loads CSS and JS from the dist directory" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "app.css"), "body { color: red; }")
        File.write(File.join(dir, "app.iife.js"), "console.log('test');")

        instance = described_class.new(dist_dir: dir)
        assets = instance.send(:dist_assets)
        expect(assets[:css]).to include("color: red")
        expect(assets[:js]).to include("console.log")
      end
    end
  end

  describe "#html_boilerplate" do
    it "generates a complete HTML document" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "app.css"), "body{}")
        File.write(File.join(dir, "app.iife.js"), "console.log(1);")

        instance = described_class.new(dist_dir: dir)
        html = instance.send(:html_boilerplate, title: "Test", body_content: "<div>Hi</div>")
        expect(html).to include("<!DOCTYPE html>")
        expect(html).to include("<title>Test</title>")
        expect(html).to include("<style>body{}</style>")
        expect(html).to include("<div>Hi</div>")
        expect(html).to include("<script>console.log(1);</script>")
      end
    end

    it "includes script data when provided" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "app.css"), "")
        File.write(File.join(dir, "app.iife.js"), "")

        instance = described_class.new(dist_dir: dir)
        html = instance.send(:html_boilerplate, title: "T", body_content: "",
                                                script_data: "var x = 1;")
        expect(html).to include("<script>\nvar x = 1;\n</script>")
      end
    end
  end

  describe "#safe_json" do
    it "escapes script-closing tags in JSON" do
      instance = described_class.new
      data = { "content" => "</script><script>alert('xss')</script>" }
      json = instance.send(:safe_json, data)
      expect(json).not_to include("</script")
      expect(json).to include("<\\/script")
    end
  end
end
