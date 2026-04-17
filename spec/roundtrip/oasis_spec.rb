# frozen_string_literal: true

RSpec.describe "OASIS DocBook fixtures" do
  Dir[File.join(__dir__, "../fixtures/oasis/*.xml")].each do |file|
    basename = File.basename(file)
    context "with #{basename}" do
      it "parses and re-serializes" do
        input = File.read(file, encoding: "bom|utf-8")
        # Force UTF-8 for files that may be in other encodings
        unless input.valid_encoding?
          input = input.encode("UTF-8", invalid: :replace, undef: :replace,
                                        replace: "?")
        end

        expect do
          parsed = Docbook::Elements::Article.from_xml(input)
          parsed.to_xml(declaration: true, encoding: "utf-8")
        end.not_to raise_error
      end
    end
  end
end
