# frozen_string_literal: true

require "spec_helper"
require "docbook/services/image_utils"

RSpec.describe Docbook::Services::ImageUtils do
  describe ".mime_type" do
    it "returns image/png for .png" do
      expect(described_class.mime_type("photo.png")).to eq("image/png")
    end

    it "returns image/jpeg for .jpg" do
      expect(described_class.mime_type("photo.jpg")).to eq("image/jpeg")
    end

    it "returns image/jpeg for .jpeg" do
      expect(described_class.mime_type("photo.jpeg")).to eq("image/jpeg")
    end

    it "returns image/gif for .gif" do
      expect(described_class.mime_type("anim.gif")).to eq("image/gif")
    end

    it "returns image/svg+xml for .svg" do
      expect(described_class.mime_type("logo.svg")).to eq("image/svg+xml")
    end

    it "returns image/webp for .webp" do
      expect(described_class.mime_type("photo.webp")).to eq("image/webp")
    end

    it "returns nil for unknown extension" do
      expect(described_class.mime_type("file.txt")).to be_nil
    end

    it "is case-insensitive" do
      expect(described_class.mime_type("photo.PNG")).to eq("image/png")
    end
  end

  describe ".embed_as_data_url" do
    it "returns nil for nil path" do
      expect(described_class.embed_as_data_url(nil)).to be_nil
    end

    it "returns nil for non-existent file" do
      expect(described_class.embed_as_data_url("/nonexistent/file.png")).to be_nil
    end

    it "embeds a real file as data URL" do
      path = File.expand_path(
        "../../fixtures/library_sample/book-one/cover.png", __dir__
      )
      result = described_class.embed_as_data_url(path)
      expect(result).to start_with("data:image/png;base64,")
    end
  end
end
