# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docbook::Elements::Cover do
  it "parses <cover> with <mediaobject>" do
    xml = <<~XML
      <cover xmlns="http://docbook.org/ns/docbook">
        <mediaobject>
          <imageobject>
            <imagedata fileref="cover.png"/>
          </imageobject>
        </mediaobject>
      </cover>
    XML
    cover = described_class.from_xml(xml)
    expect(cover.mediaobject).not_to be_empty
    expect(cover.mediaobject.first.imageobject.first.imagedata.fileref).to eq("cover.png")
  end

  it "parses empty cover element" do
    xml = '<cover xmlns="http://docbook.org/ns/docbook"/>'
    cover = described_class.from_xml(xml)
    expect(cover.mediaobject).to be_empty
  end
end
