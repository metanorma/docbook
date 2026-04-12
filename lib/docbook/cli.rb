# frozen_string_literal: true

require "thor"
require "nokogiri"
require "fileutils"

module Docbook
  class CLI < Thor
    desc "format INPUT", "Format/prettify DocBook XML"
    option :output, aliases: "-o", desc: "Output file (default: stdout)"
    option :xinclude, type: :boolean, default: false, desc: "Resolve XIncludes before processing"
    def format(input)
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      output = parsed.to_xml(pretty: true, declaration: true, encoding: "utf-8")
      write_output(output, options[:output], :single_file)
    end

    SCHEMAS_DIR = File.expand_path("schemas", __dir__)

    desc "validate INPUT", "Validate DocBook XML"
    option :schema, type: :boolean, default: true, desc: "Validate against DocBook 5 RELAX NG schema"
    option :wellformed, type: :boolean, default: false, desc: "Check well-formedness only (no schema)"
    def validate(input)
      xml_string = File.read(input)
      doc = Nokogiri::XML(xml_string)

      if doc.errors.any?
        doc.errors.each { |e| warn "#{input}: #{e}" }
        exit 1
      end

      if options[:schema] && !options[:wellformed]
        errors = validate_schema(doc, input)
        if errors.any?
          errors.each { |e| warn "#{input}: #{e}" }
          exit 1
        end
      end

      puts "#{input}: valid"
    end

    desc "to-html INPUT", "Convert DocBook XML to HTML"
    option :output, aliases: "-o", desc: "Output file or directory"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes before processing"
    option :output_type, default: :single_file, desc: "Output type: single_file or directory"
    def to_html(input)
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      xref_resolver = Docbook::XrefResolver.new(parsed).resolve!
      base_path = File.dirname(File.expand_path(input))
      output_mode = options[:output_type].to_sym
      output_path = if output_mode == :directory && options[:output]
                      File.expand_path(options[:output])
                    elsif output_mode == :single_file && options[:output]
                      File.dirname(File.expand_path(options[:output]))
                    end

      html = Docbook::Output::Html.new(
        parsed,
        xref_resolver: xref_resolver,
        output_mode: output_mode,
        base_path: base_path,
        output_path: output_path
      ).to_html

      write_output(html, options[:output], output_mode)
    end

    desc "roundtrip INPUT...", "Round-trip test DocBook XML files"
    def roundtrip(*inputs)
      failures = 0
      inputs.each do |input|
        xml_string = File.read(input)
        begin
          parsed = parse_input(xml_string)
          output = parsed.to_xml(declaration: true, encoding: "utf-8")
          reparsed = parse_input(output)
          puts "#{input}: OK"
        rescue StandardError => e
          warn "#{input}: FAIL - #{e.message}"
          failures += 1
        end
      end
      warn "#{inputs.size} files, #{failures} failures"
      exit 1 if failures > 0
    end

    def self.exit_on_failure?
      true
    end

    private

    FRONTEND_ROOT = File.expand_path("../../frontend/dist", __dir__)

    def read_input(input, resolve_xinclude = false)
      xml_string = File.read(input)
      if resolve_xinclude
        resolved = Docbook::XIncludeResolver.resolve_string(xml_string, base_path: input)
        resolved.to_xml
      else
        xml_string
      end
    end

    def parse_input(xml_string)
      Docbook::Document.from_xml(xml_string)
    end

    def validate_schema(doc, input)
      schema_file = if input_xinclude?(doc)
                      File.join(SCHEMAS_DIR, "docbookxi.rng")
                    else
                      File.join(SCHEMAS_DIR, "docbook.rng")
                    end
      rng = File.read(schema_file)
      schema = Nokogiri::XML::RelaxNG(rng)
      schema.validate(doc)
    end

    def input_xinclude?(doc)
      doc.root.namespace_definitions.any? { |ns| ns.href == "http://www.w3.org/2001/XInclude" }
    end

    def write_output(content, output_path, output_type)
      if output_type == :directory
        raise ArgumentError, "Output path required for directory mode" unless output_path

        FileUtils.mkdir_p(output_path)
        File.write(File.join(output_path, "index.html"), content)

        # Copy frontend assets to output_dir/assets/
        assets_dir = File.join(output_path, "assets")
        FileUtils.mkdir_p(assets_dir)
        FileUtils.cp(File.join(FRONTEND_ROOT, "app.css"), File.join(assets_dir, "app.css"))
        FileUtils.cp(File.join(FRONTEND_ROOT, "app.iife.js"), File.join(assets_dir, "app.iife.js"))

        puts "Written to #{File.join(output_path, "index.html")} and assets/"
      else
        if output_path
          File.write(output_path, content)
          puts "Written to #{output_path}"
        else
          $stdout.write(content)
        end
      end
    end
  end
end
