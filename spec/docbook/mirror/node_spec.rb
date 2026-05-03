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

RSpec.describe Docbook::Mirror::Node, "NODES registry" do
  it "auto-registers all subclasses via constants.each" do
    expected = %w[paragraph doc chapter section appendix part code_block image
                  table]
    expected.each do |type|
      expect(Docbook::Mirror::Node::NODES).to have_key(type),
                                              "Expected NODES to contain '#{type}'"
    end
  end

  it "maps types to correct classes" do
    expect(Docbook::Mirror::Node::NODES["paragraph"]).to eq(Docbook::Mirror::Node::Paragraph)
    expect(Docbook::Mirror::Node::NODES["chapter"]).to eq(Docbook::Mirror::Node::Chapter)
  end

  describe ".from_h round-trip" do
    it "round-trips a text node" do
      original = Docbook::Mirror::Node::Text.new(text: "hello")
      round_tripped = described_class.from_h(JSON.parse(original.to_json))

      expect(round_tripped).to be_a(Docbook::Mirror::Node::Text)
      expect(round_tripped.text).to eq("hello")
    end

    it "round-trips a chapter using base from_h" do
      original = Docbook::Mirror::Node::Chapter.new(
        attrs: { title: "Test", xml_id: "ch1" },
        content: [Docbook::Mirror::Node::Text.new(text: "Content")],
      )
      round_tripped = described_class.from_h(JSON.parse(original.to_json))

      expect(round_tripped).to be_a(Docbook::Mirror::Node::Chapter)
      expect(round_tripped.attrs[:title]).to eq("Test")
      expect(round_tripped.content.first.text).to eq("Content")
    end
  end
end
