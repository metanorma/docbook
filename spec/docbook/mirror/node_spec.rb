# frozen_string_literal: true

RSpec.describe Docbook::Mirror::Node::Text do
  describe "#to_h" do
    it "serializes with marks" do
      text = described_class.new(
        text: "must",
        marks: [Docbook::Mirror::Mark::Emphasis.new],
      )
      expect(text.to_h).to eq({
                                "type" => "text",
                                "text" => "must",
                                "marks" => [{ "type" => "emphasis" }],
                              })
    end

    it "serializes without marks" do
      text = described_class.new(text: "hello")
      expect(text.to_h).to eq({
                                "type" => "text",
                                "text" => "hello",
                              })
    end
  end

  describe "#text_content" do
    it "returns the text" do
      text = described_class.new(text: "hello world")
      expect(text.text_content).to eq("hello world")
    end
  end

  describe ".from_h" do
    it "deserializes from hash" do
      hash = {
        "type" => "text",
        "text" => "hello",
        "marks" => [{ "type" => "emphasis" }],
      }
      text = Docbook::Mirror::Node.from_h(hash)

      expect(text).to be_a(described_class)
      expect(text.text).to eq("hello")
      expect(text.marks.first).to be_a(Docbook::Mirror::Mark::Emphasis)
    end
  end
end

RSpec.describe Docbook::Mirror::Node::Paragraph do
  describe "#to_h" do
    it "serializes content" do
      para = described_class.new(content: [
                                   Docbook::Mirror::Node::Text.new(text: "Hello "),
                                   Docbook::Mirror::Node::Text.new(text: "world"),
                                 ])
      expect(para.to_h["type"]).to eq("paragraph")
      expect(para.to_h["content"].size).to eq(2)
    end
  end

  describe "#text_content" do
    it "returns combined text content" do
      para = described_class.new(content: [
                                   Docbook::Mirror::Node::Text.new(text: "Hello "),
                                   Docbook::Mirror::Node::Text.new(text: "world"),
                                 ])
      expect(para.text_content).to eq("Hello world")
    end
  end
end

RSpec.describe Docbook::Mirror::Node::Document do
  describe "#to_h" do
    it "serializes with title and content" do
      doc = described_class.new(
        attrs: { title: "Test Document" },
        content: [
          Docbook::Mirror::Node::Paragraph.new(content: [
                                                 Docbook::Mirror::Node::Text.new(text: "Hello world"),
                                               ]),
        ],
      )

      expect(doc.to_h["type"]).to eq("doc")
      expect(doc.to_h["attrs"]["title"]).to eq("Test Document")
      expect(doc.to_h["content"].first["type"]).to eq("paragraph")
    end
  end
end
