# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 8: Resolve image paths to absolute or data URLs.
      class ResolveImages
        def call(guide, context)
          xml_dir = File.dirname(context.xml_path)
          Services::ImageResolver.new(
            search_dirs: context.image_search_dirs + [xml_dir],
            strategy: context.image_strategy,
          ).resolve(guide)
          guide
        end
      end
    end
  end
end
