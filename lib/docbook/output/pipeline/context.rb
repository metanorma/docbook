# frozen_string_literal: true

module Docbook
  module Output
    # Shared state passed between pipeline steps.
    #
    # Carries configuration and the parsed document so steps can
    # communicate without coupling to each other.
    #
    # Usage:
    #   context = PipelineContext.new(xml_path: "book.xml")
    #   context.parsed  # => set by ParseXml step
    #
    PipelineContext = Struct.new(
      :xml_path,
      :image_search_dirs,
      :image_strategy,
      :sort_glossary,
      :title,
      :parsed,
      keyword_init: true
    )
  end
end
