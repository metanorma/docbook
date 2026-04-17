# frozen_string_literal: true

RSpec.describe Docbook::Elements::Book do
  context "with guide.xml (XInclude resolution)" do
    let(:guide_path) do
      File.join(__dir__, "../fixtures/xslTNG/guide/xml/guide.xml")
    end

    it "resolves XIncludes and round-trips" do
      xml_string = File.read(guide_path)
      resolved = Docbook::XIncludeResolver.resolve_string(xml_string,
                                                          base_path: guide_path)

      book = described_class.from_xml(resolved.to_xml)
      output = book.to_xml(declaration: true, encoding: "utf-8")

      expect do
        described_class.from_xml(output)
      end.not_to raise_error
    end
  end
end
