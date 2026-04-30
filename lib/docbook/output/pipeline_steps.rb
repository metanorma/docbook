# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      STEPS_DIR = "#{__dir__}/pipeline_steps".freeze

      autoload :ParseXml, "#{STEPS_DIR}/parse_xml"
      autoload :AssignIds, "#{STEPS_DIR}/assign_ids"
      autoload :GenerateToc, "#{STEPS_DIR}/generate_toc"
      autoload :GenerateNumbering, "#{STEPS_DIR}/generate_numbering"
      autoload :GenerateIndex, "#{STEPS_DIR}/generate_index"
      autoload :TransformMirror, "#{STEPS_DIR}/transform_mirror"
      autoload :AttachMetadata, "#{STEPS_DIR}/attach_metadata"
      autoload :GenerateLists, "#{STEPS_DIR}/generate_lists"
      autoload :ResolveImages, "#{STEPS_DIR}/resolve_images"
    end
  end
end
