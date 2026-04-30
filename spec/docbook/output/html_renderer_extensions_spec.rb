# frozen_string_literal: true

RSpec.describe Docbook::Output::HtmlRenderer, "extension hooks" do
  after do
    described_class.custom_node_renderers.clear
    described_class.custom_mark_renderers.clear
  end

  describe ".register_node_renderer" do
    it "overrides built-in rendering for a node type" do
      described_class.register_node_renderer("paragraph",
                                             ->(node, renderer) { "<p class=\"custom\">#{renderer.send(:render_inline, node["content"])}</p>" })

      guide = { "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello" }] }] }
      html = described_class.new(guide).render
      expect(html).to include("custom")
      expect(html).to include("Hello")
    end

    it "handles unregistered types with built-in dispatch" do
      guide = { "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Normal" }] }] }
      html = described_class.new(guide).render
      expect(html).to include("db-paragraph")
    end
  end

  describe ".register_mark_renderer" do
    it "overrides built-in mark rendering" do
      described_class.register_mark_renderer("emphasis",
                                             ->(text, _mark) { "<b>#{text}</b>" })

      guide = { "content" => [{ "type" => "paragraph", "content" => [
        { "type" => "text", "text" => "bold", "marks" => [{ "type" => "emphasis" }] },
      ] }] }
      html = described_class.new(guide).render
      expect(html).to include("<b>bold</b>")
    end
  end
end
