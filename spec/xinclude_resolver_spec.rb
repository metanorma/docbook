# frozen_string_literal: true

RSpec.describe Docbook::XIncludeResolver do
  let(:guide_path) { File.join(__dir__, "fixtures/xslTNG/guide/xml/guide.xml") }
  let(:guide_xml) { File.read(guide_path) }

  it "resolves XInclude elements" do
    resolved = described_class.resolve_string(guide_xml, base_path: guide_path)
    remaining = resolved.xpath("//xi:include", "xi" => "http://www.w3.org/2001/XInclude")
    # Only xi:includes referencing non-existent files should remain
    remaining.each do |inc|
      expect(File).not_to exist(File.join(File.dirname(guide_path),
                                          inc["href"]))
    end
  end

  it "includes chapter content after resolution" do
    resolved = described_class.resolve_string(guide_xml, base_path: guide_path)
    chapters = resolved.xpath("//db:chapter", "db" => "http://docbook.org/ns/docbook")
    expect(chapters.length).to be > 0
  end

  it "works without base_path for documents without XIncludes" do
    sample = File.read(File.join(__dir__,
                                 "fixtures/xslTNG/guide/xml/examples/sample.xml"))
    resolved = described_class.resolve_string(sample)
    expect(resolved.to_xml).to include("Sample Document")
  end
end
