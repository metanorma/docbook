# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Output::HtmlRenderer do
  subject(:renderer) { described_class.new(guide) }

  describe "#render" do
    context "with paragraphs" do
      let(:guide) do
        { "content" => [{ "type" => "paragraph",
                          "content" => [{ "type" => "text", "text" => "Hello world" }] }] }
      end

      it "renders a <p> with db-paragraph class" do
        expect(renderer.render).to include('<p class="db-paragraph">Hello world</p>')
      end
    end

    context "with code blocks" do
      let(:guide) do
        { "content" => [{ "type" => "code_block",
                          "attrs" => { "text" => "puts 'hi'", "language" => "ruby" } }] }
      end

      it "renders with language class" do
        html = renderer.render
        expect(html).to include("language-ruby")
        expect(html).to include("puts 'hi'")
      end
    end

    context "with admonitions" do
      let(:guide) do
        { "content" => [{ "type" => "admonition",
                          "attrs" => { "admonition_type" => "warning" },
                          "content" => [] }] }
      end

      it "renders with admonition type class" do
        expect(renderer.render).to include("db-admonition--warning")
      end
    end

    context "with inline marks" do
      let(:guide) do
        { "content" => [{ "type" => "paragraph",
                          "content" => [{ "type" => "text", "text" => "bold",
                                          "marks" => [{ "type" => "strong" }] }] }] }
      end

      it "renders <strong>" do
        expect(renderer.render).to include("<strong>bold</strong>")
      end
    end

    context "with sections" do
      let(:guide) do
        { "content" => [{ "type" => "chapter",
                          "attrs" => { "title" => "Intro", "xml_id" => "ch1" },
                          "content" => [] }] }
      end

      it "renders section with id and title" do
        html = renderer.render
        expect(html).to include('id="ch1"')
        expect(html).to include("Intro")
      end
    end

    context "with links" do
      let(:guide) do
        { "content" => [{ "type" => "paragraph",
                          "content" => [{ "type" => "text", "text" => "click",
                                          "marks" => [{ "type" => "link",
                                                         "attrs" => { "href" => "https://example.com" } }] }] }] }
      end

      it "renders <a> with href" do
        expect(renderer.render).to include('<a href="https://example.com">click</a>')
      end
    end

    context "with empty content" do
      let(:guide) { { "content" => [] } }

      it "returns empty string" do
        expect(renderer.render).to eq("")
      end
    end

    context "with full kitchen-sink document" do
      let(:guide) do
        Docbook::Output::Pipeline.new(
          xml_path: "spec/fixtures/kitchen-sink/kitchen-sink.xml"
        ).process
      end

      it "renders HTML with sections and paragraphs" do
        html = renderer.render
        expect(html).to include("<section")
        expect(html).to include("<p class=\"db-paragraph\">")
      end
    end
  end

  describe "#render_nodes" do
    let(:guide) { { "content" => [] } }

    it "renders a subset of nodes" do
      nodes = [
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "A" }] },
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "B" }] },
      ]
      html = described_class.new(guide).render_nodes(nodes)
      expect(html).to include("db-paragraph\">A<")
      expect(html).to include("db-paragraph\">B<")
    end
  end
end
