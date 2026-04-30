# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 6: Attach TOC, numbering, index, and metadata to the guide hash.
      #
      # Assembles the final guide structure from intermediate data produced
      # by earlier steps (toc_sections_raw, numbering, index_data, stats).
      class AttachMetadata
        def call(guide, context)
          # Merge TOC sections + numbering into toc structure
          toc_sections = guide.delete("toc_sections_raw") || []
          numbering_hash = guide.delete("numbering") || {}
          guide["toc"] = {
            "sections" => toc_sections,
            "numbering" => numbering_hash,
          }

          # Attach index
          guide["index"] = guide.delete("index_data") if guide.key?("index_data")

          # Generate and attach metadata
          stats = Services::DocumentStats.new(context.parsed).generate
          guide["meta"] = {
            "title" => stats["title"] || context.title,
            "subtitle" => stats["subtitle"],
            "author" => stats["author"],
            "pubdate" => stats["pubdate"],
            "releaseinfo" => stats["releaseinfo"],
            "copyright" => stats["copyright"],
            "cover" => stats["cover"],
            "root_element" => stats["root_element"],
          }.compact

          guide
        end
      end
    end
  end
end
