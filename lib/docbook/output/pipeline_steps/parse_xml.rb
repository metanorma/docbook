# frozen_string_literal: true

module Docbook
  module Output
    module PipelineSteps
      # Step 1: Parse DocBook XML and resolve XIncludes.
      class ParseXml
        def call(guide, context)
          require_relative "../../../docbook"
          xml_string = File.read(context.xml_path)
          resolved_xml = Docbook::XIncludeResolver.resolve_string(xml_string,
                                                                  base_path: context.xml_path)
          context.parsed = Docbook::Document.from_xml(resolved_xml.to_xml)
          guide
        end
      end
    end
  end
end
