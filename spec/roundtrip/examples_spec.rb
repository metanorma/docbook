# frozen_string_literal: true

RSpec.describe Docbook::Elements::Article do
  Dir[File.join(__dir__, "../fixtures/xslTNG/guide/xml/examples/*.xml")].each do |file|
    next unless File.basename(file).end_with?(".xml")

    basename = File.basename(file)
    context "with #{basename}" do
      let(:fixture) { File.new(file) }

      it_behaves_like "a serializer"
    end
  end
end
