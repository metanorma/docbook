# frozen_string_literal: true

module Docbook
  module Models
    # Pre-computed models for Vue SPA
    MODELS_DIR = "#{__dir__}/models".freeze

    autoload :TocNode, "#{MODELS_DIR}/toc_node"
    autoload :IndexEntry, "#{MODELS_DIR}/index_entry"
    autoload :SectionNumber, "#{MODELS_DIR}/section_number"
    autoload :ReadingPosition, "#{MODELS_DIR}/reading_position"
    autoload :DocumentMetadata, "#{MODELS_DIR}/document_metadata"
    autoload :SectionRoot, "#{MODELS_DIR}/section_root"
    autoload :DocumentRoot, "#{MODELS_DIR}/document_root"
  end
end
