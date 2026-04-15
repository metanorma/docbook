# frozen_string_literal: true

RSpec.describe Docbook::Mirror::Mark::Code do
  describe '#to_h' do
    it 'serializes with role attribute' do
      mark = described_class.new(role: 'literal')
      expect(mark.to_h).to eq({
        'type' => 'code',
        'attrs' => { 'role' => 'literal' }
      })
    end

    it 'supports all DocBook code roles' do
      roles = %w[literal code userinput computeroutput filename classname function parameter replaceable]
      roles.each do |role|
        mark = described_class.new(role: role)
        expect(mark.to_h['attrs']['role']).to eq(role)
      end
    end
  end

  describe '#from_h' do
    it 'deserializes from hash' do
      hash = { 'type' => 'code', 'attrs' => { 'role' => 'userinput' } }
      mark = Docbook::Mirror::Mark.from_h(hash)

      expect(mark).to be_a(Docbook::Mirror::Mark::Code)
      expect(mark.role).to eq('userinput')
    end
  end
end

RSpec.describe Docbook::Mirror::Mark::Emphasis do
  describe '#to_h' do
    it 'serializes correctly' do
      mark = described_class.new
      expect(mark.to_h).to eq({ 'type' => 'emphasis' })
    end
  end
end

RSpec.describe Docbook::Mirror::Mark::Link do
  describe '#to_h' do
    it 'serializes with href' do
      mark = described_class.new(href: 'http://example.com')
      expect(mark.to_h).to eq({
        'type' => 'link',
        'attrs' => { 'href' => 'http://example.com' }
      })
    end

    it 'serializes with linkend' do
      mark = described_class.new(linkend: 'section-1')
      expect(mark.to_h).to eq({
        'type' => 'link',
        'attrs' => { 'linkend' => 'section-1' }
      })
    end
  end
end