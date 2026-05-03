# frozen_string_literal: true

require "spec_helper"
require "docbook/output/pipeline_steps/assign_ids"

RSpec.describe Docbook::Output::PipelineSteps::AssignIds do
  def deep_find_all(root, klass)
    results = []
    queue = [root]
    while (el = queue.shift)
      el.walk_children do |c|
        results << c if c.is_a?(klass)
        queue << c
      end
    end
    results
  end

  it "assigns synthetic IDs to formal elements without xml:id" do
    xml = <<~XML
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="ch1">
          <title>Chapter</title>
          <figure>
            <title>An untitled figure</title>
            <mediaobject>
              <imageobject>
                <imagedata fileref="test.png"/>
              </imageobject>
            </mediaobject>
          </figure>
        </chapter>
      </book>
    XML
    parsed = Docbook::Document.from_xml(xml)
    context = instance_double(Docbook::Output::PipelineContext, parsed: parsed)
    described_class.new.call({}, context)

    figures = deep_find_all(parsed, Docbook::Elements::Figure)
    expect(figures.first.xml_id).to eq("lo-1")
  end

  it "does not overwrite existing xml:id" do
    xml = <<~XML
      <book xmlns="http://docbook.org/ns/docbook">
        <chapter xml:id="ch1">
          <title>Chapter</title>
          <figure xml:id="my-fig">
            <title>My Figure</title>
            <mediaobject>
              <imageobject>
                <imagedata fileref="test.png"/>
              </imageobject>
            </mediaobject>
          </figure>
        </chapter>
      </book>
    XML
    doc = Docbook::Document.from_xml(xml)
    context = instance_double(Docbook::Output::PipelineContext, parsed: doc)
    described_class.new.call({}, context)

    figures = deep_find_all(doc, Docbook::Elements::Figure)
    expect(figures.first.xml_id.to_s).to eq("my-fig")
  end

  it "returns the guide hash" do
    xml = '<book xmlns="http://docbook.org/ns/docbook"><title>X</title></book>'
    parsed = Docbook::Document.from_xml(xml)
    context = instance_double(Docbook::Output::PipelineContext, parsed: parsed)
    guide = {}
    result = described_class.new.call(guide, context)
    expect(result).to equal(guide)
  end
end
