# frozen_string_literal: true

RSpec.shared_examples "a serializer" do
  it "round-trips" do
    input = fixture.read
    fixture.respond_to?(:path) ? fixture.path : fixture.to_s

    serialized = described_class.from_xml(input)
    output = serialized.to_xml(declaration: true, encoding: "utf-8")

    expect do
      described_class.from_xml(output)
    end.not_to raise_error

    reparsed = described_class.from_xml(output)
    expect(reparsed).to be_a(described_class)
  end
end

RSpec.shared_examples "a canon serializer" do
  it "round-trips with canonical equivalence" do
    input = fixture.read
    fixture.respond_to?(:path) ? fixture.path : fixture.to_s

    serialized = described_class.from_xml(input)
    output = serialized.to_xml(declaration: true, encoding: "utf-8")

    expect(output).to be_xml_equivalent_to(input).with_profile(:spec_friendly)
  end
end
