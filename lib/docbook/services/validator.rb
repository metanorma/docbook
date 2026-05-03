# frozen_string_literal: true

module Docbook
  module Services
    # Validates DocBook XML documents.
    # Handles well-formedness checks and RELAX NG schema validation.
    class Validator
      ValidationResult = Struct.new(:valid?, :errors, keyword_init: true)

      SCHEMAS_DIR = File.expand_path("../schemas", __dir__)

      def initialize(input_path:)
        @input_path = input_path
      end

      # Check well-formedness only.
      # @return [ValidationResult]
      def check_wellformedness
        xml_string = File.read(@input_path)
        doc = Nokogiri::XML(xml_string)
        errors = doc.errors.map { |e| "#{@input_path}: #{e}" }

        ValidationResult.new(valid?: errors.empty?, errors: errors)
      end

      # Validate against DocBook RELAX NG schema.
      # @param doc [Nokogiri::XML::Document, nil] pre-parsed doc (optional)
      # @return [ValidationResult]
      def check_schema(doc = nil)
        doc ||= Nokogiri::XML(File.read(@input_path))
        schema_file = if xinclude?(doc)
                        File.join(SCHEMAS_DIR, "docbookxi.rng")
                      else
                        File.join(SCHEMAS_DIR, "docbook.rng")
                      end
        rng = File.read(schema_file)
        schema = Nokogiri::XML::RelaxNG(rng)
        errors = schema.validate(doc).map { |e| "#{@input_path}: #{e}" }

        ValidationResult.new(valid?: errors.empty?, errors: errors)
      end

      # Full validation: well-formedness + schema.
      # @return [ValidationResult]
      def validate
        wf = check_wellformedness
        return wf unless wf.valid?

        check_schema
      end

      private

      def xinclude?(doc)
        doc.root.namespace_definitions.any? { |ns| ns.href == "http://www.w3.org/2001/XInclude" }
      end
    end
  end
end
