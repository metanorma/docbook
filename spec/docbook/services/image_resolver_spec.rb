# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Docbook::Services::ImageResolver do
  describe "#resolve" do
    it "resolves relative image paths to file:// URLs" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "test.png"), "fake-png-data")

      data = {
        "type" => "doc",
        "content" => [
          { "type" => "image", "attrs" => { "src" => "test.png" } },
        ],
      }

      described_class.new(search_dirs: [dir], strategy: :file_url).resolve(data)

      expect(data["content"][0]["attrs"]["src"]).to start_with("file://")
      expect(data["content"][0]["attrs"]["src"]).to end_with("test.png")
    ensure
      FileUtils.remove_entry(dir)
    end

    it "skips already-absolute URLs" do
      data = {
        "type" => "doc",
        "content" => [
          { "type" => "image",
            "attrs" => { "src" => "https://example.com/img.png" } },
        ],
      }

      described_class.new(search_dirs: [], strategy: :file_url).resolve(data)

      expect(data["content"][0]["attrs"]["src"]).to eq("https://example.com/img.png")
    end

    it "skips data: URLs" do
      data = {
        "type" => "doc",
        "content" => [
          { "type" => "image",
            "attrs" => { "src" => "data:image/png;base64,abc" } },
        ],
      }

      described_class.new(search_dirs: [], strategy: :file_url).resolve(data)

      expect(data["content"][0]["attrs"]["src"]).to eq("data:image/png;base64,abc")
    end

    it "skips already-resolved file:// URLs" do
      data = {
        "type" => "image",
        "attrs" => { "src" => "file:///tmp/img.png" },
      }

      described_class.new(search_dirs: [], strategy: :file_url).resolve(data)

      expect(data["attrs"]["src"]).to eq("file:///tmp/img.png")
    end

    it "resolves images nested in content arrays" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "fig1.png"), "png-data")

      data = {
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "image", "attrs" => { "src" => "fig1.png" } },
            ],
          },
        ],
      }

      described_class.new(search_dirs: [dir], strategy: :file_url).resolve(data)

      nested = data["content"][0]["content"][0]
      expect(nested["attrs"]["src"]).to start_with("file://")
    ensure
      FileUtils.remove_entry(dir)
    end

    it "embeds as data: URL with :data_url strategy" do
      dir = Dir.mktmpdir
      File.binwrite(File.join(dir, "pic.svg"), "<svg></svg>")

      data = { "type" => "image", "attrs" => { "src" => "pic.svg" } }

      described_class.new(search_dirs: [dir], strategy: :data_url).resolve(data)

      expect(data["attrs"]["src"]).to start_with("data:image/svg+xml;base64,")
    ensure
      FileUtils.remove_entry(dir)
    end
  end
end
