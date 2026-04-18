# frozen_string_literal: true

module MirrorHelpers
  DOCBOOK_NS = 'xmlns="http://docbook.org/ns/docbook"'

  # Parse a DocBook XML fragment and transform it through the mirror pipeline.
  # Returns the Node::Document's to_h hash.
  def transform_doc(xml_string)
    require_relative "../../lib/docbook/mirror"
    doc = Docbook::Document.from_xml(xml_string)
    transformer = Docbook::Mirror::Transformer.new
    transformer.send(:from_docbook, doc)
  end

  # Parse XML wrapping the content in a <book> if needed, return the to_h hash
  def mirror_hash(xml_string)
    transform_doc(xml_string).to_h
  end

  # Like mirror_hash but accepts transformer options (e.g. sort_glossary: true)
  def mirror_hash_with(xml_string, **options)
    require_relative "../../lib/docbook/mirror"
    doc = Docbook::Document.from_xml(xml_string)
    transformer = Docbook::Mirror::Transformer.new(**options)
    transformer.send(:from_docbook, doc).to_h
  end

  # Extract the first content node matching a given type
  def find_node(hash, type)
    return hash if hash["type"] == type

    nodes = hash["content"] || []
    nodes.each do |node|
      result = find_node(node, type)
      return result if result
    end
    nil
  end

  # Collect all nodes of a given type from a hash tree
  def collect_nodes(hash, type)
    results = []
    results << hash if hash["type"] == type
    (hash["content"] || []).each do |node|
      results.concat(collect_nodes(node, type))
    end
    results
  end
end

RSpec.configure do |config|
  config.include MirrorHelpers
end
