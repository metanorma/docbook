# frozen_string_literal: true

require "nokogiri"

RSpec.describe "xslTNG test fixtures" do
  fixtures_dir = File.join(__dir__, "../fixtures/xslTNG/test/resources/xml")

  Dir[File.join(fixtures_dir, "*.xml")].each do |file|
    basename = File.basename(file)

    # Detect root element via Nokogiri
    input = File.read(file, encoding: "bom|utf-8")
    input = input.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?") unless input.valid_encoding?

    doc = Nokogiri::XML(input)
    root = doc.root
    next unless root
    ns = root.namespace&.href
    next unless ns && ns.include?("docbook")

    root_name = root.name
    next unless Docbook::Document.supports?(root_name)

    context "with #{basename} (<#{root_name}>)" do
      it "round-trips" do
        klass = Docbook::Document.from_xml(input).class

        parsed = klass.from_xml(input)
        output = parsed.to_xml(declaration: true, encoding: "utf-8")

        expect do
          klass.from_xml(output)
        end.not_to raise_error

        reparsed = klass.from_xml(output)
        expect(reparsed).to be_a(klass)
      end
    end
  end
end
