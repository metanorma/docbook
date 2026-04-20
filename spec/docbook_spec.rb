# frozen_string_literal: true

RSpec.describe Docbook do
  it "has a version number" do
    expect(Docbook::VERSION).not_to be_nil
  end
end

RSpec.describe Docbook::Elements::Article do
  let(:sample_xml) do
    File.read("spec/fixtures/xslTNG/guide/xml/examples/sample.xml")
  end

  it "parses a minimal article" do
    article = described_class.from_xml(sample_xml)
    expect(article.version).to eq("5.1")
    expect(article.info.title.content).to eq(["Sample Document"])
  end

  it "round-trips to XML" do
    article = described_class.from_xml(sample_xml)
    xml = article.to_xml
    reparsed = described_class.from_xml(xml)
    expect(reparsed.version).to eq("5.1")
    expect(reparsed.info.title.content).to eq(["Sample Document"])
  end
end
