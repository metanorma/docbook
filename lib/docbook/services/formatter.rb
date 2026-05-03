# frozen_string_literal: true

module Docbook
  module Services
    # Formats/prettifies DocBook XML documents.
    class Formatter
      def initialize(input_path:, resolve_xinclude: false)
        @input_path = input_path
        @resolve_xinclude = resolve_xinclude
      end

      # @return [String] pretty-printed XML
      def format
        xml_string = File.read(@input_path)

        if @resolve_xinclude
          xml_string = Docbook::XIncludeResolver.resolve_string(xml_string,
                                                                base_path: @input_path).to_xml
        end

        parsed = Docbook::Document.from_xml(xml_string)
        parsed.to_xml(pretty: true, declaration: true, encoding: "utf-8")
      end
    end
  end
end
