# frozen_string_literal: true

RSpec.describe Docbook::Models::SectionNumber do
  it "round-trips through JSON" do
    sn = described_class.new(id: "ch1", number: "1", type: "chapter")
    json = sn.to_json
    parsed = described_class.from_json(json)

    expect(parsed.id).to eq("ch1")
    expect(parsed.number).to eq("1")
    expect(parsed.type).to eq("chapter")
  end

  it "handles various number formats" do
    %w[I 1 1.2.3 A B].each do |num|
      sn = described_class.new(id: "x", number: num, type: "section")
      expect(described_class.from_json(sn.to_json).number).to eq(num)
    end
  end
end

RSpec.describe Docbook::Models::TocNode do
  it "round-trips flat entries through JSON" do
    node = described_class.new(id: "ch1", title: "Chapter 1", type: "chapter",
                               number: "1")
    parsed = described_class.from_json(node.to_json)

    expect(parsed.id).to eq("ch1")
    expect(parsed.title).to eq("Chapter 1")
    expect(parsed.type).to eq("chapter")
    expect(parsed.number).to eq("1")
  end

  it "round-trips nested children through JSON" do
    child = described_class.new(id: "s1", title: "Section 1", type: "section")
    parent = described_class.new(id: "ch1", title: "Chapter", type: "chapter",
                                 children: [child])
    parsed = described_class.from_json(parent.to_json)

    expect(parsed.children.size).to eq(1)
    expect(parsed.children.first.id).to eq("s1")
  end
end

RSpec.describe Docbook::Models::DocumentMetadata do
  it "round-trips through JSON with camelCase keys" do
    meta = described_class.new(
      title: "My Book",
      author_name: "Jane Doe",
      release_info: "v2.0",
    )
    json = meta.to_json
    parsed = described_class.from_json(json)

    expect(parsed.title).to eq("My Book")
    expect(parsed.author_name).to eq("Jane Doe")
    expect(parsed.release_info).to eq("v2.0")
  end
end

RSpec.describe Docbook::Models::ReadingPosition do
  it "round-trips through JSON" do
    pos = described_class.new(
      section_id: "ch1",
      percentage: 0.42,
      reading_mode: "scroll",
      scroll_position: 1200,
    )
    parsed = described_class.from_json(pos.to_json)

    expect(parsed.section_id).to eq("ch1")
    expect(parsed.percentage).to eq(0.42)
    expect(parsed.reading_mode).to eq("scroll")
    expect(parsed.scroll_position).to eq(1200)
  end
end

RSpec.describe Docbook::Models::IndexEntry do
  it "round-trips through JSON" do
    entry = described_class.new(
      primary: "Alpha",
      secondary: ["Beta"],
      see_also: ["Gamma"],
      section_id: "s1",
      sort_key: "alpha",
    )
    parsed = described_class.from_json(entry.to_json)

    expect(parsed.primary).to eq("Alpha")
    expect(parsed.secondary).to eq(["Beta"])
    expect(parsed.see_also).to eq(["Gamma"])
    expect(parsed.section_id).to eq("s1")
    expect(parsed.sort_key).to eq("alpha")
  end
end

RSpec.describe Docbook::Models::BookEntry do
  it "round-trips through JSON" do
    entry = described_class.new(id: "book1", title: "My Book", author: "Author")
    parsed = described_class.from_json(entry.to_json)

    expect(parsed.id).to eq("book1")
    expect(parsed.title).to eq("My Book")
    expect(parsed.author).to eq("Author")
  end
end

RSpec.describe Docbook::Models::CollectionManifest do
  it "round-trips through JSON with books" do
    book = Docbook::Models::BookEntry.new(id: "b1", title: "Book One")
    manifest = described_class.new(name: "Library", description: "My books",
                                   books: [book])
    parsed = described_class.from_json(manifest.to_json)

    expect(parsed.name).to eq("Library")
    expect(parsed.books.size).to eq(1)
    expect(parsed.books.first.id).to eq("b1")
  end
end

RSpec.describe Docbook::Models::DocumentRoot do
  it "round-trips through JSON with all nested models" do
    meta = Docbook::Models::DocumentMetadata.new(title: "Doc")
    toc = Docbook::Models::TocNode.new(id: "ch1", title: "Ch1", type: "chapter")
    section = Docbook::Models::SectionRoot.new(id: "ch1", type: "chapter",
                                               title: "Ch1", number: "1")
    numbering = Docbook::Models::SectionNumber.new(id: "ch1", number: "1",
                                                   type: "chapter")

    root = described_class.new(
      title: "Full Doc",
      metadata: meta,
      toc: [toc],
      sections: [section],
      numbering: [numbering],
    )
    parsed = described_class.from_json(root.to_json)

    expect(parsed.title).to eq("Full Doc")
    expect(parsed.metadata.title).to eq("Doc")
    expect(parsed.toc.first.id).to eq("ch1")
    expect(parsed.sections.first.type).to eq("chapter")
    expect(parsed.numbering.first.number).to eq("1")
  end
end
