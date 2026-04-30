# frozen_string_literal: true

RSpec.describe Docbook::Mirror::HandlerRegistry do
  let(:registry) { described_class.new }

  describe "#register and #entry_for" do
    it "registers and finds a handler" do
      handler = ->(el, ctx) { "handled" }
      registry.register(Docbook::Elements::Para, handler)

      entry = registry.entry_for(Docbook::Elements::Para.new)
      expect(entry.handler).to eq(handler)
      expect(entry.method_name).to eq(:call)
      expect(entry.concat).to eq(false)
    end

    it "returns nil for unregistered elements" do
      expect(registry.entry_for(Docbook::Elements::Para.new)).to be_nil
    end
  end

  describe "#registered?" do
    it "returns true for registered classes" do
      registry.register(Docbook::Elements::Para, ->(el, ctx) {})
      expect(registry.registered?(Docbook::Elements::Para)).to be(true)
    end

    it "returns false for unregistered classes" do
      expect(registry.registered?(Docbook::Elements::Para)).to be(false)
    end
  end

  describe "#handle" do
    it "invokes a Proc handler" do
      registry.register(Docbook::Elements::Para, ->(el, ctx) { "result" })
      result, concat = registry.handle(Docbook::Elements::Para.new, context: double("ctx"))
      expect(result).to eq("result")
      expect(concat).to eq(false)
    end

    it "passes element and context to Proc handlers" do
      received = nil
      registry.register(Docbook::Elements::Para, ->(el, ctx) { received = el; "ok" })
      el = Docbook::Elements::Para.new
      registry.handle(el, context: :test_ctx)
      expect(received).to eq(el)
    end

    it "supports concat flag" do
      registry.register(Docbook::Elements::RefNamediv,
                        ->(el, ctx) { ["a", "b"] }, concat: true)
      result, concat = registry.handle(Docbook::Elements::RefNamediv.new, context: double("ctx"))
      expect(result).to eq(["a", "b"])
      expect(concat).to eq(true)
    end

    it "returns nil for unregistered elements" do
      result = registry.handle(Docbook::Elements::Para.new, context: double("ctx"))
      expect(result).to be_nil
    end
  end

  describe "default_registry" do
    let(:default) { Docbook::Mirror.default_registry }

    it "registers Para handler" do
      expect(default.registered?(Docbook::Elements::Para)).to be(true)
    end

    it "registers all admonition types" do
      %w[Note Warning Tip Caution Important Danger].each do |type|
        klass = Docbook::Elements.const_get(type)
        expect(default.registered?(klass)).to be(true), "Expected #{type} to be registered"
      end
    end

    it "registers all section types" do
      [Docbook::Elements::Chapter, Docbook::Elements::Section,
       Docbook::Elements::Appendix, Docbook::Elements::Part,
       Docbook::Elements::Preface, Docbook::Elements::Dedication,
       Docbook::Elements::Acknowledgements, Docbook::Elements::Colophon].each do |klass|
        expect(default.registered?(klass)).to be(true), "Expected #{klass.name} to be registered"
      end
    end

    it "registers all code types" do
      [Docbook::Elements::Code, Docbook::Elements::ProgramListing,
       Docbook::Elements::Screen, Docbook::Elements::LiteralLayout].each do |klass|
        expect(default.registered?(klass)).to be(true), "Expected #{klass.name} to be registered"
      end
    end

    it "registers all list types" do
      [Docbook::Elements::OrderedList, Docbook::Elements::ItemizedList,
       Docbook::Elements::VariableList].each do |klass|
        expect(default.registered?(klass)).to be(true), "Expected #{klass.name} to be registered"
      end
    end

    it "registers RefNamediv with concat: true" do
      el = Docbook::Elements::RefNamediv.new
      entry = default.entry_for(el)
      expect(entry.concat).to eq(true)
    end

    it "registers Screen with language: text" do
      el = Docbook::Elements::Screen.new
      entry = default.entry_for(el)
      expect(entry.extra_kwargs).to eq({ language: "text" })
    end

    it "allows adding custom handlers without modifying core" do
      custom_registry = Docbook::Mirror.default_registry
      custom_registry.register(
        Docbook::Elements::Remark,
        ->(_el, _ctx) { Docbook::Mirror::Node.new(type: "custom") }
      )
      el = Docbook::Elements::Remark.new
      result, _concat = custom_registry.handle(el, context: double("ctx"))
      expect(result.type).to eq("custom")
    end
  end
end
